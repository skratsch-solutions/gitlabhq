# frozen_string_literal: true

module Authn
  module IamService
    class RejectConsentChallengeService
      REJECT_PATH = '/oauth2/internal/auth/requests/consent/reject'

      # rubocop:disable Metrics/ParameterLists -- all arguments needed
      def initialize(
        challenge:, user:, client_id:, client_name:, requested_scopes:,
        client_scopes:, ip_address: nil, user_agent: nil, client: HttpClient.new)
        # rubocop:enable Metrics/ParameterLists
        @challenge = challenge
        @user = user
        @client_id = client_id
        @client_name = client_name
        @requested_scopes = requested_scopes
        @client_scopes = client_scopes
        @ip_address = ip_address
        @user_agent = user_agent
        @client = client
      end

      def execute
        response = @client.put(
          path: REJECT_PATH,
          query_params: { challenge: @challenge },
          body: request_body
        )

        return http_error(response) unless response.success?

        redirect_to = Gitlab::Json.safe_parse(response.body)&.dig('redirect_to')

        return missing_redirect_error if redirect_to.blank?
        return invalid_redirect_error unless RedirectUrlValidator.valid?(redirect_to)

        persist_consent_record!
        emit_audit_event

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

      def persist_consent_record!
        Authn::OauthConsent.create!(
          consent_challenge: @challenge,
          user: @user,
          client_id: @client_id,
          requested_scopes: @requested_scopes,
          granted_scopes: [],
          status: :rejected
        )
      end

      def log_persistence_failure(error)
        Gitlab::AuthLogger.error(
          message: 'IAM consent record persistence failed after IAM reject',
          reason: 'consent_record_invalid',
          error: error.message,
          Labkit::Fields::GL_USER_ID => @user.id
        )
      end

      def request_body
        {
          error: 'access_denied',
          error_description: 'The user denied the request'
        }
      end

      def emit_audit_event
        audit_context = {
          name: 'user_rejected_iam_oauth_application',
          author: @user,
          scope: @user,
          target: @user,
          target_details: @client_name,
          message: 'User rejected an OAuth application.',
          additional_details: {
            application_id: @client_id,
            application_name: @client_name,
            scopes: @client_scopes,
            requested_scopes: @requested_scopes,
            granted_scopes: [],
            user_agent: @user_agent
          },
          ip_address: @ip_address
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end

      def http_error(response)
        log_failure(reason: 'http_error', http_status: response.code)
        ServiceResponse.error(
          message: "IAM consent reject failed: HTTP #{response.code}",
          reason: :iam_request_failed
        )
      end

      def missing_redirect_error
        log_failure(reason: 'missing_redirect_to')
        ServiceResponse.error(
          message: 'IAM consent reject response missing redirect_to',
          reason: :invalid_response
        )
      end

      def invalid_redirect_error
        log_failure(reason: 'invalid_redirect_url')
        ServiceResponse.error(
          message: 'IAM consent reject response contains invalid redirect URL',
          reason: :invalid_redirect_url
        )
      end

      def invalid_body_error
        log_failure(reason: 'invalid_response_body')
        ServiceResponse.error(
          message: 'IAM consent reject response has invalid body',
          reason: :invalid_response
        )
      end

      def log_failure(reason:, http_status: nil)
        Gitlab::AuthLogger.error(
          message: 'IAM consent challenge reject failed',
          reason: reason,
          Labkit::Fields::GL_USER_ID => @user.id,
          Labkit::Fields::HTTP_STATUS_CODE => http_status
        )
      end
    end
  end
end
