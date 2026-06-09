# frozen_string_literal: true

module Ci
  module StuckBuilds
    class DropCancelingService
      include DropHelpers

      OLD_TIMEOUT = 1.hour
      TIMEOUT = 30.minutes

      def execute
        Gitlab::AppLogger.info "#{self.class}: Cleaning canceling, timed-out builds"

        drop(canceling_timed_out_builds, failure_reason: :no_updates_canceling)
      end

      private

      def canceling_timed_out_builds
        Ci::Build
          .canceling
          .created_at_before(canceling_stuck_build_timeout.ago)
          .updated_at_before(canceling_stuck_build_timeout.ago)
          .order(created_at: :asc, project_id: :asc) # rubocop:disable CodeReuse/ActiveRecord -- query optimization
      end

      def canceling_stuck_build_timeout
        if Feature.enabled?(:ci_lower_stuck_build_timeouts, :instance)
          TIMEOUT
        else
          OLD_TIMEOUT
        end
      end
    end
  end
end
