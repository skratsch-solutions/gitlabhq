# frozen_string_literal: true

module Gitlab
  module Database
    # Collects a read-only PostgreSQL state snapshot for the
    # "Database information" panel on /admin/database_diagnostics.
    class DatabaseInformation
      DEFAULT_DATABASE_NAMES = %w[main].freeze

      USER_TOKEN = '$user'

      SCHEMAS_SQL = <<~SQL
        SELECT n.nspname AS name,
          (n.nspname = current_schema()) AS is_current,
          pg_catalog.pg_get_userbyid(n.nspowner) AS owner,
          EXISTS (
            SELECT 1 FROM pg_catalog.pg_class c
            WHERE c.relnamespace = n.oid AND c.relkind IN ('r', 'p', 'S')
          ) AS has_tables
        FROM pg_catalog.pg_namespace n
        WHERE n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
        ORDER BY is_current DESC, name ASC
      SQL

      def self.execute(database_names: DEFAULT_DATABASE_NAMES)
        new(database_names: database_names).execute
      end

      def initialize(database_names: DEFAULT_DATABASE_NAMES)
        @database_names = database_names
      end

      def execute
        {
          databases: @database_names.index_with { |name| collect_for_database(name) }
        }
      end

      private

      def collect_for_database(database_name)
        model = Gitlab::Database.database_base_models[database_name]
        return { error: "Unknown database: #{database_name}" } unless model

        connection = model.connection

        search_path = connection.select_value('SHOW search_path').to_s
        schemas = connection.select_all(SCHEMAS_SQL).map do |row|
          {
            name: row['name'],
            current: ActiveModel::Type::Boolean.new.cast(row['is_current']),
            owner: row['owner'],
            has_tables: ActiveModel::Type::Boolean.new.cast(row['has_tables'])
          }
        end

        current_user = connection.select_value('SELECT current_user').to_s

        {
          current_user: current_user,
          search_path: search_path,
          schemas: schemas,
          findings: search_path_findings(search_path, schemas, current_user)
        }
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, database_name: database_name)
        { error: "Failed to gather information for database: #{database_name}" }
      end

      # Inspects the live search_path against GitLab's PostgreSQL conventions
      # and returns an ordered list of findings. Each finding is a plain hash:
      # { severity: 'error'|'warning', code: String, message: String }.
      def search_path_findings(search_path, schemas, current_user)
        entries = parse_search_path(search_path)
        partition_schema_names = Gitlab::Database::EXTRA_SCHEMAS.map(&:to_s)

        findings = []

        if (entries & partition_schema_names).any?
          findings << {
            severity: 'warning',
            code: 'search_path_contains_partition_schema',
            message: s_('DatabaseDiagnostics|The search path contains a GitLab partition schema. ' \
              'Partition schemas are expected to be referenced fully qualified, not via the search path.')
          }
        end

        # Resolve the "$user" token to the connected role so a user-named schema
        # is considered, and drop partition schemas (covered above). What remains
        # are the candidate schemas the search path resolves objects against.
        candidate_names = entries.map { |entry| entry == USER_TOKEN ? current_user : entry } -
          partition_schema_names
        populated = schemas.select do |schema|
          candidate_names.include?(schema[:name]) && schema[:has_tables]
        end

        if populated.size > 1
          findings << {
            severity: 'warning',
            code: 'search_path_objects_split_across_schemas',
            message: format(
              s_('DatabaseDiagnostics|More than one schema in the search path contains objects: %{schemas}. ' \
                'GitLab\'s objects should all live in a single schema. If they are split across ' \
                'multiple schemas, unqualified references can resolve unexpectedly.'),
              schemas: populated.pluck(:name).join(', ')
            )
          }
        end

        findings
      end

      # Normalizes a raw search_path string into an ordered list of tokens,
      # stripping whitespace and surrounding double quotes while preserving
      # the "$user" token.
      def parse_search_path(search_path)
        search_path.split(',').map do |entry|
          entry.strip.delete_prefix('"').delete_suffix('"')
        end
      end
    end
  end
end
