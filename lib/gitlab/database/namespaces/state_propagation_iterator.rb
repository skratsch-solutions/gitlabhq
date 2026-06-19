# frozen_string_literal: true

module Gitlab
  module Database
    module Namespaces
      # Tree iterator used by the state-propagation worker.
      # See https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/group_and_project_operations_and_state_management/decisions/003_state_propagation_model/
      class StatePropagationIterator < ::Gitlab::Database::NamespaceEachBatch
        def initialize(namespace_class:, cursor:, state_filter:)
          super(namespace_class: namespace_class, cursor: cursor)

          @state_filter = state_filter
        end

        private

        attr_reader :state_filter

        def namespace_exists_query
          super.with_state(state_filter)
        end

        def walk_down_lateral_query
          super.with_state(state_filter)
        end

        def next_elements_lateral_query
          super.with_state(state_filter)
        end
      end
    end
  end
end
