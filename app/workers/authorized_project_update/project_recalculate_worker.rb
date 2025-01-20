# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculateWorker
    include ApplicationWorker

    data_consistency :sticky, feature_flag: :change_data_consistency_for_permissions_workers
    include Gitlab::ExclusiveLeaseHelpers

    feature_category :permissions
    urgency :high
    queue_namespace :authorized_project_update

    deduplicate :until_executed, if_deduplicated: :reschedule_once, including_scheduled: true

    idempotent!

    def perform(project_id)
      project = Project.find_by_id(project_id)
      return unless project

      service = AuthorizedProjectUpdate::ProjectRecalculateService.new(project)

      recalculate(project, service)
    end

    def recalculate(project, service)
      if Feature.enabled?(:drop_lease_usage_project_recalculate_workers, Feature.current_request)
        service.execute
      else
        in_lock(lock_key(project), ttl: 10.seconds) do
          service.execute
        end
      end
    end

    private

    def lock_key(project)
      # The self.class.name.underscore value is hardcoded here as the prefix, so that the same
      # lock_key for this superclass will be used by the ProjectRecalculatePerUserWorker subclass.
      "authorized_project_update/project_recalculate_worker/projects/#{project.id}"
    end
  end
end
