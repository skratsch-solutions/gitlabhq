# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: proto/claim_service.proto for package 'Gitlab.Cells.TopologyService'

require 'grpc'
require 'proto/claim_service_pb'

module Gitlab
  module Cells
    module TopologyService
      module ClaimService
        # Restricted read-write service to claim global uniqueness on resources
        class Service

          include ::GRPC::GenericService

          self.marshal_class_method = :encode
          self.unmarshal_class_method = :decode
          self.service_name = 'gitlab.cells.topology_service.ClaimService'

          rpc :GetCells, ::Gitlab::Cells::TopologyService::GetCellsRequest, ::Gitlab::Cells::TopologyService::GetCellsResponse
          rpc :CreateClaim, ::Gitlab::Cells::TopologyService::CreateClaimRequest, ::Gitlab::Cells::TopologyService::CreateClaimResponse
        end

        Stub = Service.rpc_stub_class
      end
    end
  end
end
