# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iam::ConsentController, :use_clean_rails_memory_store_caching,
  feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:oauth_application) { create(:oauth_application) }

  let(:iam_service_url) { 'https://iam.example.com' }
  let(:iam_secret) { 'test-secret-token' }
  let(:challenge) { 'a' * 64 }
  let(:client_id) { oauth_application.uid }
  let(:redirect_url) { "#{iam_service_url}/oauth2/authorize?consent_verifier=#{'b' * 64}" }
  let(:reject_redirect_url) { "#{iam_service_url}/oauth2/authorize?error=access_denied" }
  let(:requested_scopes) { %w[openid profile] }
  let(:client_name) { 'Test App' }
  let(:client_scopes) { %w[openid profile email] }

  let(:consent_response_body) do
    {
      skip: false,
      subject: user.id.to_s,
      requested_scope: requested_scopes,
      client: {
        'client_id' => client_id,
        'client_name' => client_name,
        'owner' => 'GitLab User',
        'created_at' => '2025-01-01T00:00:00Z',
        'scopes' => client_scopes
      }
    }
  end

  let(:get_response) do
    instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: consent_response_body.to_json)
  end

  let(:accept_response) do
    instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
      body: { redirect_to: redirect_url }.to_json)
  end

  let(:reject_response) do
    instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
      body: { redirect_to: reject_redirect_url }.to_json)
  end

  let(:cache_key) { "iam:consent_data:#{user.id}:#{challenge}" }

  before do
    stub_feature_flags(iam_svc_login: true)
    allow(Authn::IamAuthService).to receive_messages(
      enabled?: true,
      url: iam_service_url,
      secret: iam_secret
    )
    sign_in(user)
    allow(Gitlab::HTTP).to receive_messages(get: get_response, put: accept_response)
  end

  shared_examples 'isolates cached consent by user' do
    let_it_be(:other_user) { create(:user) }

    before do
      get iam_consent_path, params: { consent_challenge: challenge }
      sign_in(other_user)
      allow(Gitlab::AuthLogger).to receive(:error)
    end

    it 'rejects the cross-user request without calling IAM', :aggregate_failures do
      expect { request }.not_to change { Authn::OauthConsent.count }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(response.body).to include('An error has occurred')
      expect(Gitlab::HTTP).not_to have_received(:put)
      expect(Gitlab::AuthLogger).to have_received(:error).with(
        hash_including(message: 'Consent session expired or already used')
      )
    end

    it 'leaves the initiating user cached consent intact' do
      request

      cached = Rails.cache.read(cache_key)
      expect(cached).to eq(
        {
          subject: user.id.to_s,
          client_id: client_id,
          client_name: client_name,
          requested_scopes: requested_scopes,
          client_scopes: client_scopes
        }
      )
    end
  end

  describe 'GET #show' do
    subject(:request) { get iam_consent_path, params: { consent_challenge: challenge } }

    it 'renders the consent form with client name and scope titles', :aggregate_failures do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('is requesting access to your account')
      expect(response.body).to include('Test App')
      expect(response.body).to include('GitLab User added this OAuth application')
    end

    it 'writes consent data to the cache keyed by challenge', :aggregate_failures do
      request

      cached = Rails.cache.read(cache_key)
      expect(cached).to eq(
        {
          subject: user.id.to_s,
          client_id: client_id,
          client_name: client_name,
          requested_scopes: requested_scopes,
          client_scopes: client_scopes
        }
      )
    end

    context 'when the IAM subject does not match the current user' do
      let(:consent_response_body) { super().merge(subject: 'someone-else') }

      it 'returns 400', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to include('An error has occurred')
      end
    end

    context 'when the current user is an admin' do
      let_it_be(:user) { create(:admin) }

      it 'renders an admin warning' do
        request

        expect(response.body).to include('You are an administrator')
      end
    end

    context 'when skip_consent is true' do
      let(:consent_response_body) { super().merge(skip: true) }

      it 'auto-accepts and redirects without caching', :aggregate_failures do
        expect { request }.to change { Authn::OauthConsent.count }.by(1)

        expect(response).to redirect_to(redirect_url)
        expect(Rails.cache.read(cache_key)).to be_nil
      end
    end

    context 'with an invalid consent_challenge param' do
      it 'returns 400 when missing', :aggregate_failures do
        get iam_consent_path

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to include('An error has occurred')
      end
    end

    context 'when the iam_svc_login feature flag is disabled' do
      before do
        stub_feature_flags(iam_svc_login: false)
      end

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the IAM service is disabled' do
      before do
        allow(Authn::IamAuthService).to receive(:enabled?).and_return(false)
      end

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user email is not confirmed' do
      let_it_be(:user) { create(:user, :unconfirmed) }

      it 'returns 400', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to include('An error has occurred')
      end
    end

    context 'when the IAM service returns an upstream error' do
      let(:get_response) do
        instance_double(Gitlab::HTTP::Response, success?: false, code: 400, body: '{}')
      end

      it 'returns 502', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:bad_gateway)
        expect(response.body).to include('An error has occurred')
      end
    end
  end

  describe 'POST #accept' do
    subject(:request) { post accept_iam_consent_path, params: { consent_challenge: challenge } }

    context 'when the consent form was rendered first' do
      before do
        get iam_consent_path, params: { consent_challenge: challenge }
      end

      it 'redirects to the IAM redirect URL', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:see_other)
        expect(response).to redirect_to(redirect_url)
      end

      it 'creates an authorized consent record from cached data', :aggregate_failures do
        expect { request }.to change { Authn::OauthConsent.count }.by(1)

        consent = Authn::OauthConsent.last
        expect(consent.user).to eq(user)
        expect(consent.client_id).to eq(client_id)
        expect(consent.requested_scopes).to eq(requested_scopes)
        expect(consent.granted_scopes).to eq(requested_scopes)
        expect(consent).to be_authorized
      end

      context 'when the IAM accept request returns an upstream error' do
        let(:accept_response) do
          instance_double(Gitlab::HTTP::Response, success?: false, code: 500, body: '{}')
        end

        it 'returns 502 without persisting a record', :aggregate_failures do
          request

          expect(response).to have_gitlab_http_status(:bad_gateway)
          expect(response.body).to include('An error has occurred')
          expect(Authn::OauthConsent.count).to eq(0)
        end
      end

      context 'when the IAM accept response has an invalid redirect URL' do
        let(:accept_response) do
          instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
            body: { redirect_to: 'https://untrusted.example.com/oauth2/authorize' }.to_json)
        end

        it 'returns 400', :aggregate_failures do
          request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('An error has occurred')
        end
      end

      context 'when persisting the consent record raises RecordNotUnique' do
        before do
          create(:oauth_consent, consent_challenge: challenge, user: user, client_id: client_id)
        end

        it 'returns 400', :aggregate_failures do
          request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('An error has occurred')
        end
      end

      context 'when the same challenge is submitted twice' do
        it 'returns 400 on the second submit', :aggregate_failures do
          2.times { post accept_iam_consent_path, params: { consent_challenge: challenge } }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('An error has occurred')
          expect(Authn::OauthConsent.count).to eq(1)
        end
      end
    end

    context 'when a different signed-in user attempts to consume the cached challenge' do
      it_behaves_like 'isolates cached consent by user'
    end

    context 'when the consent form was not rendered first' do
      it 'returns 400', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to include('An error has occurred')
        expect(Authn::OauthConsent.count).to eq(0)
      end
    end
  end

  describe 'POST #reject' do
    subject(:request) { post reject_iam_consent_path, params: { consent_challenge: challenge } }

    context 'when the consent form was rendered first' do
      before do
        allow(Gitlab::HTTP).to receive(:put).and_return(reject_response)
        get iam_consent_path, params: { consent_challenge: challenge }
      end

      it 'redirects to the IAM reject redirect URL', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:see_other)
        expect(response).to redirect_to(reject_redirect_url)
      end

      it 'creates a rejected consent record from cached data', :aggregate_failures do
        expect { request }.to change { Authn::OauthConsent.count }.by(1)

        consent = Authn::OauthConsent.last
        expect(consent.user).to eq(user)
        expect(consent.client_id).to eq(client_id)
        expect(consent.requested_scopes).to eq(requested_scopes)
        expect(consent.granted_scopes).to eq([])
        expect(consent).to be_rejected
      end

      it 'consumes the cache entry so a subsequent accept is rejected', :aggregate_failures do
        request

        expect(Rails.cache.read(cache_key)).to be_nil

        post accept_iam_consent_path, params: { consent_challenge: challenge }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      context 'when the IAM reject request returns an upstream error' do
        let(:reject_response) do
          instance_double(Gitlab::HTTP::Response, success?: false, code: 500, body: '')
        end

        it 'returns 502', :aggregate_failures do
          request

          expect(response).to have_gitlab_http_status(:bad_gateway)
          expect(response.body).to include('An error has occurred')
        end
      end

      context 'when the IAM reject request raises a transport failure' do
        before do
          allow(Gitlab::HTTP).to receive(:put).and_raise(Errno::ECONNREFUSED)
          allow(Gitlab::ErrorTracking).to receive(:track_exception)
        end

        it 'returns 502', :aggregate_failures do
          request

          expect(response).to have_gitlab_http_status(:bad_gateway)
          expect(response.body).to include('An error has occurred')
        end
      end
    end

    context 'when a different signed-in user attempts to consume the cached challenge' do
      it_behaves_like 'isolates cached consent by user'
    end

    context 'when the consent form was not rendered first' do
      it 'returns 400', :aggregate_failures do
        request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to include('An error has occurred')
      end
    end
  end
end
