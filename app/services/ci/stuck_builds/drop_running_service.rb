# frozen_string_literal: true

module Ci
  module StuckBuilds
    class DropRunningService
      include DropHelpers

      OLD_BUILD_RUNNING_OUTDATED_TIMEOUT = 1.hour
      BUILD_RUNNING_OUTDATED_TIMEOUT = 30.minutes

      def execute
        Gitlab::AppLogger.info "#{self.class}: Cleaning running, timed-out builds"

        Ci::Partition.find_each do |partition|
          drop(running_stuck_builds(partition), failure_reason: :no_updates_running)
        end
      end

      private

      def running_stuck_builds(partition)
        Ci::Build
          .not_timed_out_running_builds
          .updated_at_before(build_running_outdated_timeout.ago)
          .in_partition(partition.id)
      end

      def build_running_outdated_timeout
        if Feature.enabled?(:ci_lower_stuck_build_timeouts, :instance)
          BUILD_RUNNING_OUTDATED_TIMEOUT
        else
          OLD_BUILD_RUNNING_OUTDATED_TIMEOUT
        end
      end
    end
  end
end
