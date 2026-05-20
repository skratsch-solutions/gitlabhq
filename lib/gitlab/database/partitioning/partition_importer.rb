# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class PartitionImporter
        include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

        ImportError = Class.new(StandardError)

        # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
        def initialize(connection:)
          @connection = connection
        end

        # @param table_definitions [Array<Hash>]
        # @param dry_run [Boolean] when true, report what would be created without executing DDL
        # @return [Hash]
        #   { created: Integer, skipped: Integer, tables_processed: Integer }
        def import(table_definitions, dry_run: false)
          totals = { created: 0, skipped: 0, tables_processed: 0 }
          errors = []

          table_definitions.each do |table_def|
            process_table(table_def, dry_run: dry_run, totals: totals, errors: errors)
          end

          raise ImportError, error_summary(errors) if errors.any?

          totals
        end

        private

        attr_reader :connection

        def execute(sql)
          @connection.execute(sql)
        end

        def process_table(table_def, dry_run:, totals:, errors:)
          table_name = table_def[:table_name] || table_def['table_name']
          partitions_data = table_def[:partitions] || table_def['partitions'] || []

          return unless connection.table_exists?(table_name)

          totals[:tables_processed] += 1
          missing = missing_partitions(table_name, partitions_data, errors)

          apply_partitions(missing, dry_run: dry_run)
          totals[:created] += missing.size
          totals[:skipped] += partitions_data.size - missing.size
        rescue StandardError => e
          Gitlab::AppLogger.error(
            message: 'Failed to import partitions',
            table_name: table_name,
            exception_class: e.class,
            exception_message: e.message
          )

          errors << format('table=%<table>s error=%<class>s: %<message>s',
            table: table_name,
            class: e.class,
            message: e.message)
        end

        def apply_partitions(partitions, dry_run:)
          return if partitions.empty?

          dry_run ? log_dry_run(partitions) : create_partitions(partitions)
        end

        def missing_partitions(table_name, partitions_data, errors)
          existing = existing_partition_bounds(table_name)

          partitions_data.filter_map do |partition_data|
            partition_name = partition_data[:partition_name] || partition_data['partition_name']
            from_value = partition_data[:from] || partition_data['from']
            to_value = partition_data[:to] || partition_data['to']

            begin
              from = Integer(from_value)
              to = Integer(to_value)
            rescue ArgumentError, TypeError
              Gitlab::AppLogger.warn(
                message: 'Skipping invalid partition definition',
                table_name: table_name,
                partition_name: partition_name,
                from: from_value,
                to: to_value
              )

              errors << format('table=%<table>s partition=%<partition>s from=%<from>p to=%<to>p (invalid definition)',
                table: table_name,
                partition: partition_name || 'unknown',
                from: from_value,
                to: to_value)
              next
            end

            next if existing.any? { |partition| partition[:from] == from && partition[:to] == to }

            IntRangePartition.new(table_name, from, to, partition_name: partition_name)
          rescue StandardError => e
            Gitlab::AppLogger.warn(
              message: 'Skipping invalid partition bounds',
              table_name: table_name,
              partition_name: partition_name,
              from: from,
              to: to,
              exception_class: e.class,
              exception_message: e.message
            )

            errors << format('table=%<table>s partition=%<partition>s from=%<from>p to=%<to>p (%<class>s: %<message>s)',
              table: table_name,
              partition: partition_name || 'unknown',
              from: from,
              to: to,
              class: e.class,
              message: e.message)
            nil
          end
        end

        def existing_partition_bounds(table_name)
          Gitlab::Database::SharedModel.using_connection(connection) do
            Gitlab::Database::PostgresPartition.for_parent_table(table_name).filter_map do |partition|
              int_partition = IntRangePartition.from_sql(table_name, partition.name, partition.condition)

              { from: int_partition.from, to: int_partition.to }
            rescue ArgumentError
              nil
            end
          end
        end

        def create_partitions(partitions)
          Gitlab::Database::SharedModel.using_connection(connection) do
            WithPartitioningLockRetries.new(
              klass: self.class,
              logger: Gitlab::AppLogger,
              connection: connection
            ).run(raise_on_exhaustion: true) do
              connection.transaction(requires_new: false) do
                partitions.each do |partition|
                  @connection.execute(partition.to_create_sql)
                  @connection.execute(partition.to_attach_sql)
                  process_created_partition(partition)

                  Gitlab::AppLogger.info(
                    message: 'Imported partition',
                    partition_name: partition.partition_name,
                    table_name: partition.table
                  )
                end
              end
            end
          end
        end

        def log_dry_run(partitions)
          partitions.each do |partition|
            Gitlab::AppLogger.info(
              message: 'Dry run: would create partition',
              partition_name: partition.partition_name,
              table_name: partition.table,
              from: partition.from,
              to: partition.to
            )
          end
        end

        def error_summary(errors)
          message = ['Partition import completed with errors:']
          errors.each { |error| message << "- #{error}" }
          message.join("\n")
        end

        def process_created_partition(partition)
          partition_identifier = "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partition.partition_name}"

          return unless has_loose_foreign_key?(partition.table)

          track_record_deletions_override_table_name(partition_identifier, partition.table)
        end
      end
    end
  end
end
