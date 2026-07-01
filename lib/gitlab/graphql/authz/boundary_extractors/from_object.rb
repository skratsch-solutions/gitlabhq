# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      module BoundaryExtractors
        # Extracts boundaries from an already-resolved object used for queries
        # If input is `boundary: :owner`, the resolved boundary is object.owner
        class FromObject < Base
          def initialize(directives, object)
            super(directives)
            @object = object
          end

          private

          def concrete_resource(directive)
            method_name = boundary_method(directive)
            return @object if method_name == ITSELF
            return unless method_name

            @object.try(method_name)
          end
        end
      end
    end
  end
end
