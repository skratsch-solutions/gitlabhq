# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      module BoundaryExtractors
        # Extracts the set of boundary objects from `authorize_granular_token` directives
        class Base
          STANDALONE_BOUNDARIES = [:user, :instance].freeze
          ITSELF = :itself

          def initialize(directives)
            @directives = directives
          end

          # A concrete boundary is a specific project/group record the token must be scoped to,
          # as opposed to a standalone (:user/:instance) boundary.
          # Concrete boundaries take precedence.
          # Standalone boundaries are only used when no concrete boundary is found.
          def extract
            concrete = []
            standalone = []

            directives.each do |directive|
              if standalone?(directive)
                standalone << boundary_type(directive)
              else
                resource = concrete_resource(directive)
                concrete << resource if resource && matches_boundary_type?(directive, resource)
              end
            end

            return concrete.uniq if concrete.any?

            standalone.uniq
          end

          private

          attr_reader :directives

          def concrete_resource(_directive)
            raise Gitlab::AbstractMethodError
          end

          # The same `boundary` method can resolve to different types, so we skip
          # directives whose resolved object isn't the declared `boundary_type`.
          # E.g. Ci::RunnerType declares directive -> `boundary: :owner, boundary_type: :project`
          # when the object being authorized is an instance runner,
          # the boundary_object is instance_runner.owner = User
          # which doesn't match the expected, `boundary_type: :project`. Hence, we skip that boundary.
          def matches_boundary_type?(directive, resource)
            return false if resource.nil?

            resource.class.name.underscore == boundary_type(directive).to_s
          end

          def standalone?(directive)
            STANDALONE_BOUNDARIES.include?(boundary_type(directive))
          end

          def boundary_type(directive)
            directive.arguments[:boundary_type]&.to_sym
          end

          def boundary_method(directive)
            directive.arguments[:boundary]&.to_sym
          end
        end
      end
    end
  end
end
