# frozen_string_literal: true

require_relative 'database_change_lock_window'

module Tooling
  module Danger
    module DatabaseUpgradeDdlLock
      include DatabaseChangeLockWindow

      BACKGROUND_ISSUE_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/579388'
      SCHEMA_FILE_PATTERN = %r{\Adb/structure\.sql}

      def check_ddl_lock_contention
        return unless config_file_exists? && config_valid?

        warn warning_message if should_warn?
        fail lock_message if should_fail?
      end

      # Uniform entry point used by Tooling::Danger::DatabaseChangeLock.
      alias_method :check_database_lock, :check_ddl_lock_contention

      private

      def should_warn?
        within_warning_period? && schema_modified?
      end

      def should_fail?
        schema_modified? && lock_active? && helper.ci?
      end

      def schema_modified?
        helper.all_changed_files.grep(SCHEMA_FILE_PATTERN).any?
      end

      def lock_message
        format(lock_message_template, message_params)
      end

      def lock_message_template
        <<~MSG
          Merging migrations that change schema is currently disabled while a major database upgrade is
          performed. After the lock expires, retry this job and danger will pass.

          See change request: %<upgrade_issue_url>s

          Maintenance starts at: %<maintenance_start_date>s
          Merge lock started at: %<merge_lock_start_date>s
          Locked until: %<end_date>s
          Details: %<details>s
          Background: #{BACKGROUND_ISSUE_URL}
        MSG
      end

      def warning_message
        format(warning_message_template, message_params.merge(days_until_lock: days_until_lock))
      end

      def warning_message_template
        <<~MSG
          A database upgrade lock will be active in %<days_until_lock>s day(s). Starting at %<merge_lock_start_date>s, merging
          migrations that changes the schema (DDL) will be disabled. The maintenance window is scheduled for %<maintenance_start_date>s,
          but merges are blocked %<merge_buffer_days>s day(s) earlier to allow time for deployment ahead of the upgrade.

          See change request: %<upgrade_issue_url>s

          Maintenance starts at: %<maintenance_start_date>s
          Merge lock starts at: %<merge_lock_start_date>s
          Locked until: %<end_date>s
          Details: %<details>s
          Background: #{BACKGROUND_ISSUE_URL}
        MSG
      end
    end
  end
end
