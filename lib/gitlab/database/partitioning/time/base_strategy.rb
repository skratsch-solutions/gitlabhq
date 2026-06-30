# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      module Time
        class BaseStrategy < Gitlab::Database::Partitioning::BaseStrategy
          RETAIN_FOREVER = :ever

          attr_reader :model, :partitioning_key, :retain_for, :retain_non_empty_partitions, :analyze_interval

          delegate :table_name, to: :model

          def initialize(
            model, partitioning_key, retain_for:, retain_non_empty_partitions: false,
            analyze_interval: nil)
            @model = model
            @partitioning_key = partitioning_key
            @retain_for = retention_period(retain_for)
            @retain_non_empty_partitions = retain_non_empty_partitions
            @analyze_interval = analyze_interval
          end

          def current_partitions
            raise NotImplementedError
          end

          # Check the currently existing partitions and determine which ones are missing
          def missing_partitions
            raise NotImplementedError
          end

          def extra_partitions
            raise NotImplementedError
          end

          def desired_partitions
            raise NotImplementedError
          end

          def relevant_range
            raise NotImplementedError
          end

          def after_adding_partitions
            # No-op, required by the partition manager
          end

          def validate_and_fix
            # No-op, required by the partition manager
          end

          def oldest_active_date
            raise NotImplementedError
          end

          def partition_name(lower_bound)
            raise NotImplementedError
          end

          private

          # Validates and normalizes `retain_for`. `:ever` is accepted as readable
          # input but normalized to `nil`, so the returned value is always a
          # duration or `nil` (no retention limit). Anything else raises.
          def retention_period(retain_for)
            return if retain_for == RETAIN_FOREVER
            return retain_for if retain_for.is_a?(ActiveSupport::Duration)

            raise ArgumentError,
              "retain_for must be an ActiveSupport::Duration (for example, `6.months`) " \
                "or `:ever` to retain all partitions, got: #{retain_for.inspect}"
          end

          def partition_for(upper_bound:, lower_bound: nil)
            TimePartition.new(table_name, lower_bound, upper_bound, partition_name: partition_name(lower_bound))
          end

          def pruning_old_partitions?
            retain_for.present?
          end
        end
      end
    end
  end
end
