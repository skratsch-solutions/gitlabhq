# frozen_string_literal: true

module Gitlab
  module PolicyStore
    module Ports
      # Contract every storage backend must satisfy. The in-memory adapter
      # implements it today; a future remote (e.g. gRPC) adapter would implement
      # the same interface, keeping the facade and callers unchanged.
      class PolicyRepository
        def store(_attributes)
          raise NotImplementedError
        end

        def find(_id)
          raise NotImplementedError
        end

        def list(organization_id:)
          raise NotImplementedError
        end
      end
    end
  end
end
