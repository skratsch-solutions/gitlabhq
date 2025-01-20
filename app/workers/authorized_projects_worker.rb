# frozen_string_literal: true

class AuthorizedProjectsWorker
  include ApplicationWorker

  data_consistency :sticky, feature_flag: :change_data_consistency_for_permissions_workers

  sidekiq_options retry: 3

  feature_category :permissions
  urgency :high
  weight 2

  deduplicate :until_executed, if_deduplicated: :reschedule_once, including_scheduled: true

  idempotent!
  loggable_arguments 1 # For the job waiter key

  def perform(user_id)
    user = User.find_by_id(user_id)

    return unless user

    refresh_service = Users::RefreshAuthorizedProjectsService.new(user, source: self.class.name)

    if Feature.enabled?(:drop_lease_usage_authorized_projects_worker, Feature.current_request)
      refresh_service.execute_without_lease
    else
      refresh_service.execute
    end
  end
end
