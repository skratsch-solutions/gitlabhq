# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::RejectConsentChallengeService, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:oauth_application) { create(:oauth_application) }

  let(:iam_service_url) { 'https://iam.example.com' }
  let(:iam_secret) { 'test-secret-token' }
  let(:challenge) { 'a' * 64 }
  let(:client_id) { oauth_application.uid }
  let(:client_name) { 'Test App' }
  let(:requested_scopes) { %w[openid profile email] }
  let(:client_scopes) { %w[openid profile email] }
  let(:ip_address) { '198.51.100.42' }
  let(:user_agent) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)' }
  let(:redirect_url) { "#{iam_service_url}/oauth2/authorize?error=access_denied" }

  let(:service) do
    described_class.new(
      challenge: challenge,
      user: user,
      client_id: client_id,
      client_name: client_name,
      requested_scopes: requested_scopes,
      client_scopes: client_scopes,
      ip_address: ip_address,
      user_agent: user_agent
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
          "#{iam_service_url}#{described_class::REJECT_PATH}?challenge=#{challenge}",
          hash_including(
            body: {
              error: 'access_denied',
              error_description: 'The user denied the request'
            }.to_json,
            headers: { 'Content-Type' => 'application/json',
                       Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => iam_secret },
            timeout: Authn::IamService::HttpClient::TIMEOUT_SECONDS
          )
        )
      end

      it 'creates a rejected consent record', :aggregate_failures do
        expect { result }.to change { Authn::OauthConsent.count }.by(1)

        consent = Authn::OauthConsent.last
        expect(consent.consent_challenge).to eq(challenge)
        expect(consent.user).to eq(user)
        expect(consent.client_id).to eq(client_id)
        expect(consent.requested_scopes).to eq(requested_scopes)
        expect(consent.granted_scopes).to eq([])
        expect(consent).to be_rejected
      end

      it 'emits an audit event' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with({
          name: 'user_rejected_iam_oauth_application',
          author: user,
          scope: user,
          target: user,
          target_details: client_name,
          message: 'User rejected an OAuth application.',
          additional_details: {
            application_id: client_id,
            application_name: client_name,
            scopes: client_scopes,
            requested_scopes: requested_scopes,
            granted_scopes: [],
            user_agent: user_agent
          },
          ip_address: ip_address
        })

        result
      end

      context 'when ip_address and user_agent are not provided' do
        let(:service) do
          described_class.new(
            challenge: challenge,
            user: user,
            client_id: client_id,
            client_name: client_name,
            requested_scopes: requested_scopes,
            client_scopes: client_scopes
          )
        end

        it 'emits an audit event with nil ip_address and user_agent' do
          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
            hash_including(
              ip_address: nil,
              additional_details: hash_including(user_agent: nil)
            )
          )

          result
        end
      end
    end

    context 'when the consent record already exists' do
      before do
        create(:oauth_consent, consent_challenge: challenge, user: user, client_id: client_id)
      end

      it 'returns an error and logs the failure', :aggregate_failures do
        expect(Gitlab::AuthLogger).to receive(:error).with(
          hash_including(
            message: 'IAM consent record persistence failed after IAM reject',
            reason: 'consent_record_invalid',
            Labkit::Fields::GL_USER_ID => user.id
          )
        )

        expect(result).to be_error
        expect(result.reason).to eq(:consent_record_invalid)
      end

      it_behaves_like 'does not create a consent record'
    end

    context 'when IAM returns an HTTP error' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: false, code: 400,
          body: { error: 'Invalid challenge' }.to_json)
      end

      it_behaves_like 'does not create a consent record'

      include_examples 'iam service error response with user',
        reason: :iam_request_failed,
        message: 'IAM consent reject failed: HTTP 400'

      include_examples 'does not emit IAM consent audit event'
    end

    context 'when redirect_to is missing' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { some_other_field: 'value' }.to_json)
      end

      it_behaves_like 'does not create a consent record'

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM consent reject response missing redirect_to'

      include_examples 'does not emit IAM consent audit event'
    end

    context 'when the response body is nil' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: nil)
      end

      it_behaves_like 'does not create a consent record'

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM consent reject response missing redirect_to'

      include_examples 'does not emit IAM consent audit event'
    end

    context 'when the response body is invalid JSON' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: 'not json{')
      end

      it_behaves_like 'does not create a consent record'

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM consent reject response has invalid body'

      include_examples 'does not emit IAM consent audit event'
    end

    context 'when redirect_to is an untrusted URL' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { redirect_to: 'https://untrusted.example.com/oauth2/authorize' }.to_json)
      end

      it_behaves_like 'does not create a consent record'

      include_examples 'iam service error response with user',
        reason: :invalid_redirect_url,
        message: 'IAM consent reject response contains invalid redirect URL'

      include_examples 'does not emit IAM consent audit event'
    end

    include_examples 'iam service transport failure', http_method: :put
  end
end
