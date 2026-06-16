# frozen_string_literal: true

module RequestPayloadLogger
  extend ActiveSupport::Concern
  include Gitlab::Logging::CloudflareHelper
  include Gitlab::Logging::JsonMetadataHelper

  def append_info_to_payload(payload)
    super

    payload[:ua] = request.env["HTTP_USER_AGENT"]
    payload[:remote_ip] = request.remote_ip
    payload[Labkit::Fields::CORRELATION_ID] = Labkit::Correlation::CorrelationId.current_id

    payload[:metadata] = Gitlab::ApplicationContext.current

    if defined?(urgency)
      payload[:request_urgency] = urgency&.name
      payload[:target_duration_s] = urgency&.duration
    end

    logged_user = auth_user

    if logged_user.present?
      payload[:user_id] = logged_user.try(:id)
      payload[:username] = logged_user.try(:username)
      payload[:user_is_bot] = logged_user.try(:bot?)
    end

    append_oauth_info_to_payload(payload)

    payload[:queue_duration_s] = request.env[::Gitlab::Middleware::RailsQueueDuration::GITLAB_RAILS_QUEUE_DURATION_KEY]
    store_cloudflare_headers!(payload, request)
    store_json_metadata_headers!(payload, request)
  end

  private

  def append_oauth_info_to_payload(payload)
    return unless doorkeeper_token.present?

    payload[:oauth_application_id] = doorkeeper_token.application_id
    payload[:oauth_application_name] = doorkeeper_token.application&.name
    payload[:oauth_scopes] = doorkeeper_token.scopes.to_s
    payload[:is_mcp_request] = doorkeeper_token.scopes.include?('mcp')
  end
end
