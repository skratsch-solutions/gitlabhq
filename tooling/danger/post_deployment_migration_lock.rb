# frozen_string_literal: true

require_relative 'database_change_lock_window'

module Tooling
  module Danger
    module PostDeploymentMigrationLock
      include DatabaseChangeLockWindow

      BACKGROUND_URL = 'https://gitlab.com/gitlab-com/gl-infra/change-lock/-/blob/master/config/changelock.yml'
      SOFT_PCL_DOC_URL = 'https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/change-management/#soft-pcl'
      POST_DEPLOYMENT_MIGRATION_FILE_PATTERN = %r{\A(ee/)?db/post_migrate/}

      def check_pdm_lock_contention
        return unless config_file_exists? && config_valid?

        warn warning_message if should_warn?
        fail lock_message if should_fail?
      end

      # Uniform entry point used by Tooling::Danger::DatabaseChangeLock.
      alias_method :check_database_lock, :check_pdm_lock_contention

      private

      def should_warn?
        within_warning_period? && post_deployment_migration_added?
      end

      def should_fail?
        post_deployment_migration_added? && lock_active? && helper.ci?
      end

      def post_deployment_migration_added?
        helper.added_files.grep(POST_DEPLOYMENT_MIGRATION_FILE_PATTERN).any?
      end

      def lock_message
        format(lock_message_template, message_params)
      end

      def lock_message_template
        <<~MSG
          Merging post-deployment migrations (PDMs) is currently disabled because a soft Production Change Lock (PCL)
          is in effect. PDMs are not executed during a soft PCL, so merging new ones would pile them up and grow the
          backlog that has to run once the PCL ends, increasing the size and risk of that post-PCL migration run.
          After the lock expires, retry this job and danger will pass.

          See change request: %<upgrade_issue_url>s

          Soft PCL starts at: %<maintenance_start_date>s
          Merge lock started at: %<merge_lock_start_date>s
          Locked until: %<end_date>s
          Details: %<details>s
          What is a soft PCL: #{SOFT_PCL_DOC_URL}
          Background: #{BACKGROUND_URL}
        MSG
      end

      def warning_message
        format(warning_message_template, message_params.merge(days_until_lock: days_until_lock))
      end

      def warning_message_template
        <<~MSG
          A post-deployment migration (PDM) lock will be active in %<days_until_lock>s day(s). Starting at %<merge_lock_start_date>s,
          merging new PDMs will be disabled because PDMs are not executed during the upcoming soft Production Change Lock (PCL),
          and merging them anyway would pile them up into a larger, riskier post-PCL migration run.
          The soft PCL is scheduled for %<maintenance_start_date>s, but merges are blocked %<merge_buffer_days>s day(s) earlier
          so already-merged PDMs deploy ahead of the PCL.

          See change request: %<upgrade_issue_url>s

          Soft PCL starts at: %<maintenance_start_date>s
          Merge lock starts at: %<merge_lock_start_date>s
          Locked until: %<end_date>s
          Details: %<details>s
          What is a soft PCL: #{SOFT_PCL_DOC_URL}
          Background: #{BACKGROUND_URL}
        MSG
      end
    end
  end
end
