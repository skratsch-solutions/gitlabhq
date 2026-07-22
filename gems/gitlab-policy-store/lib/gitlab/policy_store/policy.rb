# frozen_string_literal: true

module Gitlab
  module PolicyStore
    # Immutable, ActiveRecord-free representation of a policy. This is what the
    # facade returns to callers, so no persistence object ever crosses the
    # component boundary.
    #
    # A policy belongs to an organization, targets a single trigger, and carries
    # its rules and actions as structured data. Scope is held both as authored
    # data (`policy_scope`) and its compiled Rego form (`scope_rego`). `mode` is
    # one of audit/warn/enforce; `lifecycle_state` tracks whether it is active.
    class Policy
      attr_reader :id, :organization_id, :name, :version, :trigger_id,
        :rules, :actions, :policy_scope, :scope_rego, :mode, :lifecycle_state

      # rubocop:disable Metrics/ParameterLists -- value object; one keyword per field
      def initialize(
        id:, organization_id:, name:, trigger_id:, version: 1, rules: {}, actions: [],
        policy_scope: nil, scope_rego: nil, mode: 'enforce', lifecycle_state: 'active')
        # rubocop:enable Metrics/ParameterLists
        @id = id
        @organization_id = organization_id
        @name = name
        @version = version
        @trigger_id = trigger_id
        @rules = rules
        @actions = actions
        @policy_scope = policy_scope
        @scope_rego = scope_rego
        @mode = mode
        @lifecycle_state = lifecycle_state

        freeze
      end

      def to_h
        {
          id: id,
          organization_id: organization_id,
          name: name,
          version: version,
          trigger_id: trigger_id,
          rules: rules,
          actions: actions,
          policy_scope: policy_scope,
          scope_rego: scope_rego,
          mode: mode,
          lifecycle_state: lifecycle_state
        }
      end

      def ==(other)
        other.is_a?(self.class) && other.to_h == to_h
      end
      alias_method :eql?, :==

      def hash
        to_h.hash
      end
    end
  end
end
