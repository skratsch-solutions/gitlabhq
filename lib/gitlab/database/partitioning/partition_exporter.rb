# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      # Export integer range partition definitions for a given connection
      # so they can be imported into another cell prior to PG replication,
      # to avoid insertion errors.
      class PartitionExporter
        INTEGER_TYPES = %w[integer bigint].freeze

        # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
        def initialize(connection:)
          @connection = connection
        end

        # @return [Array<Hash>]
        #   Array of { table_name: String, partitions: Array<Hash> } where each
        #   partition is { partition_name: String, from: Integer, to: Integer }.
        def export
          results = []

          Gitlab::Database::SharedModel.using_connection(@connection) do
            range_tables = Gitlab::Database::PostgresPartitionedTable.where(strategy: 'range')

            range_tables.each do |table|
              next unless integer_partition_key?(table)

              partitions = export_partitions_for(table)
              results << { table_name: table.name, partitions: partitions }
            end
          end

          results.sort_by { |result| result[:table_name] }
        end

        private

        def integer_partition_key?(table)
          key_column = table.key_columns.first
          return false unless key_column

          type = @connection.select_value(<<~SQL, nil, [key_column, table.identifier])
            SELECT format_type(a.atttypid, a.atttypmod)
            FROM pg_attribute a
            WHERE a.attrelid = $2::regclass
              AND a.attname = $1
              AND a.attnum > 0
          SQL

          INTEGER_TYPES.include?(type)
        end

        def export_partitions_for(table)
          table.postgres_partitions.filter_map do |partition|
            int_partition = IntRangePartition.from_sql(table.name, partition.name, partition.condition)
            { partition_name: int_partition.partition_name, from: int_partition.from, to: int_partition.to }
          rescue ArgumentError
            nil
          end
        end
      end
    end
  end
end
