# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::GetConsentChallengeService, feature_category: :system_access do
  let(:iam_service_url) { 'https://iam.example.com' }
  let(:iam_secret) { 'test-secret-token' }
  let(:challenge) { 'a' * 64 }

  let(:service) { described_class.new(challenge: challenge) }

  subject(:result) { service.execute }

  before do
    allow(Authn::IamAuthService).to receive_messages(
      url: iam_service_url,
      secret: iam_secret
    )
  end

  describe '#execute' do
    let(:consent_response_body) do
      {
        skip: false,
        subject: '123',
        requested_scope: %w[openid profile],
        client: {
          'client_id' => 'test-app',
          'client_name' => 'Test App',
          'owner' => 'GitLab User',
          'created_at' => '2025-01-01T00:00:00Z',
          'scopes' => %w[openid profile email]
        }
      }
    end

    let(:http_response) do
      instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
        body: consent_response_body.to_json)
    end

    before do
      allow(Gitlab::HTTP).to receive(:get).and_return(http_response)
    end

    context 'when the response is valid' do
      it 'returns the flattened consent payload', :aggregate_failures do
        expect(result).to be_success
        expect(result.payload.keys).to match_array(
          %i[skip_consent subject requested_scopes
            client_id client_name client_owner client_created_at client_scopes]
        )
        expect(result.payload[:skip_consent]).to be(false)
        expect(result.payload[:subject]).to eq('123')
        expect(result.payload[:requested_scopes]).to eq(%w[openid profile])
        expect(result.payload[:client_id]).to eq('test-app')
        expect(result.payload[:client_name]).to eq('Test App')
        expect(result.payload[:client_owner]).to eq('GitLab User')
        expect(result.payload[:client_created_at]).to eq(Time.zone.parse('2025-01-01T00:00:00Z'))
        expect(result.payload[:client_scopes]).to eq(%w[openid profile email])
      end

      it 'sends the GET request to IAM' do
        result

        expect(Gitlab::HTTP).to have_received(:get).with(
          "#{iam_service_url}#{described_class::CONSENT_REQUEST_PATH}?consent_challenge=#{challenge}",
          hash_including(
            headers: { 'Content-Type' => 'application/json',
                       Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => iam_secret },
            timeout: Authn::IamService::HttpClient::TIMEOUT_SECONDS
          )
        )
      end
    end

    context 'when subject is an integer' do
      let(:consent_response_body) { super().merge(subject: 123) }

      it 'coerces it to a string' do
        expect(result.payload[:subject]).to eq('123')
      end
    end

    context 'when skip is the string "true"' do
      let(:consent_response_body) { super().merge(skip: 'true') }

      it 'parses it as true' do
        expect(result.payload[:skip_consent]).to be(true)
      end
    end

    context 'when requested_scope is missing' do
      let(:consent_response_body) { super().except(:requested_scope) }

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent response missing mandatory fields: requested_scopes'
    end

    context 'when a mandatory client field is missing' do
      let(:consent_response_body) { super().tap { |b| b[:client].delete('owner') } }

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent response missing mandatory fields: client_owner'
    end

    context 'when IAM returns an HTTP error' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: false, code: 400,
          body: { error: 'Invalid challenge' }.to_json)
      end

      include_examples 'iam service error response',
        reason: :iam_request_failed,
        message: 'IAM consent request failed: HTTP 400'
    end

    context 'when the response body is nil' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: nil)
      end

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent request response has invalid body'
    end

    context 'when the response body is invalid JSON' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: 'not json{')
      end

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent request response has invalid body'
    end

    context 'when the client object is missing' do
      let(:consent_response_body) { super().except(:client) }

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent response missing mandatory fields: ' \
          'client_id, client_name, client_owner, client_created_at, client_scopes'
    end

    context 'when client_id is missing' do
      let(:consent_response_body) do
        super().merge(client: super()[:client].except('client_id'))
      end

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent response missing mandatory fields: client_id'
    end

    context 'when client_created_at is unparseable' do
      let(:consent_response_body) { super().tap { |b| b[:client]['created_at'] = 'not-a-date' } }

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent response missing mandatory fields: client_created_at'
    end

    context 'when client_created_at is nil' do
      let(:consent_response_body) { super().tap { |b| b[:client]['created_at'] = nil } }

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent response missing mandatory fields: client_created_at'
    end

    context 'when client.scopes is missing' do
      let(:consent_response_body) { super().tap { |b| b[:client].delete('scopes') } }

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent response missing mandatory fields: client_scopes'
    end

    context 'when client.scopes is an empty array' do
      let(:consent_response_body) { super().tap { |b| b[:client]['scopes'] = [] } }

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent response missing mandatory fields: client_scopes'
    end

    include_examples 'iam service transport failure', http_method: :get
  end
end
