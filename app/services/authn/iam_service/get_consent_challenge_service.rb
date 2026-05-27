# frozen_string_literal: true

module Authn
  module IamService
    class GetConsentChallengeService
      CONSENT_REQUEST_PATH = '/oauth2/internal/auth/requests/consent'

      MANDATORY_FIELDS = %i[
        subject requested_scopes client_id client_name client_owner client_created_at client_scopes
      ].freeze

      def initialize(challenge:, client: HttpClient.new)
        @challenge = challenge
        @client = client
      end

      def execute
        response = @client.get(
          path: CONSENT_REQUEST_PATH,
          query_params: { consent_challenge: @challenge }
        )

        return http_error(response) unless response.success?

        parsed = Gitlab::Json.safe_parse(response.body)

        return invalid_body_error unless parsed.is_a?(Hash)

        oauth_client = parsed['client'] || {}

        payload = {
          skip_consent: Gitlab::Utils.to_boolean(parsed['skip']),
          subject: parsed['subject'].to_s,
          requested_scopes: Array(parsed['requested_scope']),
          client_id: oauth_client['client_id'],
          client_name: oauth_client['client_name'],
          client_owner: oauth_client['owner'],
          client_created_at: Time.zone.parse(oauth_client['created_at'].to_s),
          client_scopes: Array(oauth_client['scopes'])
        }

        missing = MANDATORY_FIELDS.select { |f| payload[f].blank? }
        return missing_mandatory_fields_error(missing) if missing.any?

        ServiceResponse.success(payload: payload)
      rescue HttpClient::RequestError => e
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      rescue JSON::ParserError
        invalid_body_error
      end

      private

      def http_error(response)
        log_failure(reason: 'http_error', http_status: response.code)
        ServiceResponse.error(
          message: "IAM consent request failed: HTTP #{response.code}",
          reason: :iam_request_failed
        )
      end

      def invalid_body_error
        log_failure(reason: 'invalid_response_body')
        ServiceResponse.error(
          message: 'IAM consent request response has invalid body',
          reason: :invalid_response
        )
      end

      def missing_mandatory_fields_error(fields)
        log_failure(reason: 'missing_mandatory_fields')
        ServiceResponse.error(
          message: "IAM consent response missing mandatory fields: #{fields.join(', ')}",
          reason: :invalid_response
        )
      end

      def log_failure(reason:, http_status: nil)
        Gitlab::AuthLogger.error(
          message: 'IAM consent request failed',
          reason: reason,
          Labkit::Fields::HTTP_STATUS_CODE => http_status
        )
      end
    end
  end
end
