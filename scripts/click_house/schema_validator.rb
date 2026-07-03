# frozen_string_literal: true

module ClickHouse
  class SchemaValidator
    SCHEMA_FILENAME = "db/click_house/main.sql" # Only supporting main schema, for now
    SCHEMA_MIGRATIONS_DIR = "db/click_house/schema_migrations"
    SKIP_VALIDATION_LABEL = 'pipeline:skip-check-clickhouse-schema'
    DOC_URL = "https://docs.gitlab.com/development/database/clickhouse/reviewer_guidelines.html#ensuring-database-schema-consistency"

    def self.validate!
      if skip_validation?
        puts "\e[32mLabel #{SKIP_VALIDATION_LABEL} is present, skipping schema validation\e[0m"
        return true
      end

      puts "Running ClickHouse migrations..."
      migration_success = system("bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main")

      unless migration_success
        puts "ERROR: ClickHouse migration failed"
        return false
      end

      schema_is_clean = validate_schema_file
      version_files_are_clean = validate_schema_version_files

      schema_is_clean && version_files_are_clean
    end

    def self.validate_schema_file
      puts "Checking for schema changes..."
      diff_output = execute_git_diff

      unless diff_output
        puts "ERROR: Git diff command failed"
        return false
      end

      # rubocop:disable Rails/NegateInclude -- called without Rails context, no ActiveSupport methods available.
      schema_is_clean = !diff_output.include?(SCHEMA_FILENAME)
      # rubocop:enable Rails/NegateInclude

      if schema_is_clean
        puts "Schema is up to date - no changes detected"
      else
        puts "Schema has uncommitted changes after migration"
        puts "Changes detected in: #{SCHEMA_FILENAME}"
        puts "Diff output:"
        puts `git diff -- #{SCHEMA_FILENAME}`
        puts skip_message
      end

      schema_is_clean
    end

    def self.validate_schema_version_files
      puts "Checking for schema version file changes..."
      status_output = execute_git_add_dry_run

      unless status_output
        puts "ERROR: Git command failed"
        return false
      end

      version_files_are_clean = status_output.empty?

      if version_files_are_clean
        puts "Schema version files are up to date - no changes detected"
      else
        puts "The committed files in #{SCHEMA_MIGRATIONS_DIR} do not match those expected by the added migrations"
        puts "Uncommitted changes:"
        puts status_output
        puts skip_message
      end

      version_files_are_clean
    end

    def self.execute_git_diff
      output = `git diff --name-only -- #{SCHEMA_FILENAME}`
      output if git_command_successful?
    end

    def self.execute_git_add_dry_run
      output = `git add -A -n #{SCHEMA_MIGRATIONS_DIR}`
      output if git_command_successful?
    end

    def self.git_command_successful?
      $?.success?
    end

    def self.skip_message
      "Please investigate. Apply the '#{SKIP_VALIDATION_LABEL}' label to skip this check if needed. " \
        "If you are unsure why this job is failing for your MR, then please refer to this page: " \
        "#{DOC_URL}"
    end

    def self.skip_validation?
      ENV.fetch('CI_MERGE_REQUEST_LABELS', '').split(',').include?(SKIP_VALIDATION_LABEL)
    end
  end
end
