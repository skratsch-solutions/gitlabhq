# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::AcceptConsentChallengeService, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:oauth_application) { create(:oauth_application) }

  let(:iam_service_url) { 'https://iam.example.com' }
  let(:iam_secret) { 'test-secret-token' }
  let(:challenge) { 'a' * 64 }
  let(:granted_scopes) { %w[openid profile] }
  let(:client_id) { oauth_application.uid }
  let(:requested_scopes) { %w[openid profile] }
  let(:redirect_url) { "#{iam_service_url}/oauth2/authorize?consent_verifier=#{'b' * 64}" }

  let(:service) do
    described_class.new(
      challenge: challenge,
      user: user,
      granted_scopes: granted_scopes,
      client_id: client_id,
      requested_scopes: requested_scopes
    )
  end

  subject(:result) { service.execute }

  before do
    allow(Authn::IamAuthService).to receive_messages(
      url: iam_service_url,
      secret: iam_secret
    )
  end

  describe '#execute' do
    let(:http_response) do
      instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
        body: { redirect_to: redirect_url }.to_json)
    end

    before do
      allow(Gitlab::HTTP).to receive(:put).and_return(http_response)
    end

    context 'when the response is valid' do
      it 'returns the redirect URL', :aggregate_failures do
        expect(result).to be_success
        expect(result.payload[:redirect_to]).to eq(redirect_url)
      end

      it 'sends the PUT request to IAM' do
        result

        expect(Gitlab::HTTP).to have_received(:put).with(
          "#{iam_service_url}#{described_class::ACCEPT_PATH}?challenge=#{challenge}",
          hash_including(
            body: {
              grant_scope: granted_scopes,
              session: {
                access_token: { username: user.username },
                id_token: { name: user.name, email: user.email }
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json',
                       Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => iam_secret },
            timeout: Authn::IamService::HttpClient::TIMEOUT_SECONDS
          )
        )
      end

      it 'creates a consent record', :aggregate_failures do
        expect { result }.to change { Authn::OauthConsent.count }.by(1)

        consent = Authn::OauthConsent.last
        expect(consent.consent_challenge).to eq(challenge)
        expect(consent.user).to eq(user)
        expect(consent.client_id).to eq(client_id)
        expect(consent.requested_scopes).to eq(requested_scopes)
        expect(consent.granted_scopes).to eq(granted_scopes)
        expect(consent).to be_authorized
      end
    end

    context 'when the consent record already exists' do
      before do
        create(:oauth_consent, consent_challenge: challenge, user: user, client_id: client_id)
      end

      it 'returns an error and logs the failure', :aggregate_failures do
        expect(Gitlab::AuthLogger).to receive(:error).with(
          hash_including(
            message: 'IAM consent record persistence failed after IAM accept',
            reason: 'consent_record_invalid',
            Labkit::Fields::GL_USER_ID => user.id
          )
        )

        expect(result).to be_error
        expect(result.reason).to eq(:consent_record_invalid)
      end

      it 'does not create a second record' do
        expect { result }.not_to change { Authn::OauthConsent.count }
      end
    end

    context 'when IAM returns an HTTP error' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: false, code: 400,
          body: { error: 'Failed to accept consent' }.to_json)
      end

      it 'does not create a consent record' do
        expect { result }.not_to change { Authn::OauthConsent.count }
      end

      include_examples 'iam service error response with user',
        reason: :iam_request_failed,
        message: 'IAM consent accept failed: HTTP 400'
    end

    context 'when redirect_to is missing' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { something_else: 'value' }.to_json)
      end

      it 'does not create a consent record' do
        expect { result }.not_to change { Authn::OauthConsent.count }
      end

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM consent accept response missing redirect_to'
    end

    context 'when redirect_to is blank' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { redirect_to: '' }.to_json)
      end

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM consent accept response missing redirect_to'
    end

    context 'when the response body is nil' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: nil)
      end

      it 'does not create a consent record' do
        expect { result }.not_to change { Authn::OauthConsent.count }
      end

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM consent accept response missing redirect_to'
    end

    context 'when the response body is invalid JSON' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: 'not json{')
      end

      it 'does not create a consent record' do
        expect { result }.not_to change { Authn::OauthConsent.count }
      end

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM consent accept response has invalid body'
    end

    context 'when redirect_to is an untrusted URL' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { redirect_to: 'https://untrusted.example.com/oauth2/authorize' }.to_json)
      end

      it 'does not create a consent record' do
        expect { result }.not_to change { Authn::OauthConsent.count }
      end

      include_examples 'iam service error response with user',
        reason: :invalid_redirect_url,
        message: 'IAM consent accept response contains invalid redirect URL'
    end

    include_examples 'iam service transport failure', http_method: :put
  end
end
