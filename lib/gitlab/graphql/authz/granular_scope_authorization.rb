# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authz
      class GranularScopeAuthorization
        STANDALONE_BOUNDARIES = [:user, :instance].freeze
        ITSELF = :itself

        attr_reader :directives

        delegate :empty?, :any?, to: :directives

        def initialize(directives)
          @directives = directives.select { |directive| directive.is_a?(::Directives::Authz::GranularScope) }
        end

        def ok?(object, context)
          token = context[:access_token]
          return true unless token && token.try(:granular?)

          return true if object.nil?

          # if no gPAT directives are defined, granular token should deny access
          return false if directives.empty?

          authorized?(object, context)
        end

        private

        def permissions
          @permissions ||= directives.first.arguments.fetch(:permissions, []).sort
        end

        def authorized?(object, context)
          boundary_objects = resolve_boundaries(object)
          key = cache_key(boundary_objects)

          fetch_cached(context, key) do
            ::Authz::Tokens::AuthorizeGranularScopesService.new(
              boundaries: boundary_objects.map { |resource| ::Authz::Boundary.for(resource) },
              permissions: permissions,
              token: context[:access_token]
            ).execute.success?
          end
        end

        def fetch_cached(context, key)
          cache = context[:granular_scope_authz_cache] ||= {}
          return cache[key] if cache.key?(key)

          cache[key] = yield
        end

        def cache_key(boundary_objects)
          [
            permissions,
            boundary_objects.map { |boundary| cache_identifier_for(boundary) }.sort_by(&:to_s)
          ]
        end

        def cache_identifier_for(boundary_object)
          return boundary_object if boundary_object.is_a?(Symbol)

          [boundary_object.class.name, boundary_object.id]
        end

        # TODO: resolve N+1 https://gitlab.com/gitlab-org/gitlab/-/work_items/600920
        # Resolves the object to its concrete boundaries, falling back to standalone boundaries
        # only when no concrete boundary resolves.
        def resolve_boundaries(object)
          concrete = []
          standalone = []

          directives.each do |directive|
            if standalone?(directive)
              standalone << boundary_type(directive)
            else
              boundary = resolve_boundary(directive, object)
              concrete << boundary if boundary
            end
          end

          return concrete.uniq if concrete.any?

          standalone.uniq
        end

        def resolve_boundary(directive, object)
          boundary_object = extract_resource(directive, object)
          boundary_object if matches_boundary_type?(directive, boundary_object)
        end

        def extract_resource(directive, object)
          method_name = boundary_method(directive)
          return object if method_name == ITSELF

          object.try(method_name)
        end

        # The same `boundary` method can resolve to different types, so we skip
        # directives whose resolved object isn't the declared `boundary_type`.
        # E.g. Ci::RunnerType declares directive -> `boundary: :owner, boundary_type: :project`
        # when the object being authorized is an instance runner,
        # the boundary_object is instance_runner.owner = User
        # which doesn't match the expected, `boundary_type: :project`. Hence, we skip that boundary.
        def matches_boundary_type?(directive, boundary_object)
          return false if boundary_object.nil?

          boundary_object.class.name.underscore == boundary_type(directive).to_s
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
