# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      module BoundaryExtractors
        # Extracts boundaries from GraphQL arguments, used for mutations
        # If the input is `boundary_argument: :project_path`, the resolved boundary is project
        class FromInputArguments < Base
          def initialize(directives, arguments)
            super(directives)
            @arguments = arguments
          end

          private

          def concrete_resource(directive)
            boundary_argument = directive.arguments[:boundary_argument]
            return unless boundary_argument

            record = locate(@arguments[boundary_argument.to_sym])
            return unless record

            return record if record.is_a?(::Project) || record.is_a?(::Group)

            method_name = boundary_method(directive)
            return unless method_name

            record.try(method_name)
          end

          def locate(value)
            case value
            when GlobalID then ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(value))
            when String then ::Project.find_by_full_path(value) || ::Group.find_by_full_path(value)
            end
          rescue ActiveRecord::RecordNotFound
            nil
          end
        end
      end
    end
  end
end
