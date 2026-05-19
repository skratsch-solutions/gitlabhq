# frozen_string_literal: true

module Authn
  module IamService
    class AcceptConsentChallengeService
      ACCEPT_PATH = '/oauth2/internal/auth/requests/consent/accept'

      def initialize(challenge:, user:, granted_scopes:, client_id:, requested_scopes:, client: HttpClient.new)
        @challenge = challenge
        @user = user
        @granted_scopes = granted_scopes
        @client_id = client_id
        @requested_scopes = requested_scopes
        @client = client
      end

      def execute
        response = @client.put(
          path: ACCEPT_PATH,
          query_params: { challenge: @challenge },
          body: request_body
        )

        return http_error(response) unless response.success?

        redirect_to = Gitlab::Json.safe_parse(response.body)&.dig('redirect_to')

        return missing_redirect_error if redirect_to.blank?
        return invalid_redirect_error unless RedirectUrlValidator.valid?(redirect_to)

        persist_consent_record!

        # TODO: emit audit event (deferred to follow-up MR).

        ServiceResponse.success(payload: { redirect_to: redirect_to })
      rescue HttpClient::RequestError => e
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      rescue JSON::ParserError
        invalid_body_error
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        log_persistence_failure(e)
        ServiceResponse.error(message: e.message, reason: :consent_record_invalid)
      end

      private

      def request_body
        {
          grant_scope: @granted_scopes,
          session: {
            access_token: { username: @user.username },
            id_token: { name: @user.name, email: @user.email }
          }
        }
      end

      def persist_consent_record!
        Authn::OauthConsent.create!(
          consent_challenge: @challenge,
          user: @user,
          client_id: @client_id,
          requested_scopes: @requested_scopes,
          granted_scopes: @granted_scopes,
          status: :authorized
        )
      end

      def log_persistence_failure(error)
        Gitlab::AuthLogger.error(
          message: 'IAM consent record persistence failed after IAM accept',
          reason: 'consent_record_invalid',
          error: error.message,
          Labkit::Fields::GL_USER_ID => @user.id
        )
      end

      def http_error(response)
        log_failure(reason: 'http_error', http_status: response.code)
        ServiceResponse.error(
          message: "IAM consent accept failed: HTTP #{response.code}",
          reason: :iam_request_failed
        )
      end

      def missing_redirect_error
        log_failure(reason: 'missing_redirect_to')
        ServiceResponse.error(
          message: 'IAM consent accept response missing redirect_to',
          reason: :invalid_response
        )
      end

      def invalid_redirect_error
        log_failure(reason: 'invalid_redirect_url')
        ServiceResponse.error(
          message: 'IAM consent accept response contains invalid redirect URL',
          reason: :invalid_redirect_url
        )
      end

      def invalid_body_error
        log_failure(reason: 'invalid_response_body')
        ServiceResponse.error(
          message: 'IAM consent accept response has invalid body',
          reason: :invalid_response
        )
      end

      def log_failure(reason:, http_status: nil)
        Gitlab::AuthLogger.error(
          message: 'IAM consent challenge accept failed',
          reason: reason,
          Labkit::Fields::GL_USER_ID => @user.id,
          Labkit::Fields::HTTP_STATUS_CODE => http_status
        )
      end
    end
  end
end
