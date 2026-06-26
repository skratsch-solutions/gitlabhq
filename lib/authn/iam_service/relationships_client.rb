# frozen_string_literal: true

module Authn
  module IamService
    # gRPC client for the IAM Relationships API write path (update.v1.UpdateService).
    #
    # Callers present an AR-scoped bearer token minted by the Rails token exchange
    # (Authn::TokenExchange::TokenIssuer). IAM validates the token and authorizes
    # the caller server-side -- this client does not perform authorization.
    class RelationshipsClient < BaseClient
      RequestError = Class.new(StandardError)

      TIMEOUT_SECONDS = 5

      # Assigns a role to a subject on an object by writing an ASSIGNMENT tuple.
      # The caller passes the identity pieces and this client owns the tuple shape.
      #
      # @param organization_id [Integer] the subject's home organization (origin)
      # @param user_id [Integer] the subject user (local id)
      # @param resource_id [String] UUID of the object the role applies to
      # @param role_id [String] UUID of the role to assign
      # @param token [String] AR-scoped JWT presented as a bearer credential
      # @return [Update::V1::WriteRelationshipsResponse]
      def assign_role(organization_id:, user_id:, resource_id:, role_id:, token:)
        input = assignment_input(organization_id, user_id, resource_id, role_id)

        write_relationships([input], token: token)
      end

      # Upserts the given assignment tuples. All-or-nothing on the server.
      #
      # @param relationship_inputs [Array<Relationships::V1::RelationshipInput>]
      # @param token [String] AR-scoped JWT presented as a bearer credential
      # @return [Update::V1::WriteRelationshipsResponse]
      def write_relationships(relationship_inputs, token:)
        request = ::Gitlab::Iam::Update::V1::WriteRelationshipsRequest.new(relationships: relationship_inputs)

        client.write_relationships(request, metadata: bearer_metadata(token))
      rescue ::Authn::IamDataAccessService::ConfigurationError => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError, 'The Artifact Registry service is unavailable.'
      rescue GRPC::BadStatus => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError, "IAM Relationships API write failed: #{e.code}"
      end

      private

      def assignment_input(organization_id, user_id, resource_id, role_id)
        ::Gitlab::Iam::Relationships::V1::RelationshipInput.new(
          subject: ::Gitlab::Iam::Relationships::V1::Subject.new(
            identity: ::Gitlab::Iam::Relationships::V1::Identity.new(
              origin: :ORIGIN_SELF,
              origin_id: organization_id.to_s,
              local_id: user_id.to_s
            )
          ),
          object: ::Gitlab::Iam::Relationships::V1::Object.new(id: resource_id),
          kind: :KIND_ASSIGNMENT,
          role: ::Gitlab::Iam::Relationships::V1::Role.new(id: role_id)
        )
      end

      def client
        # Address + transport config is owned by the IAM data access service
        # (Authn::IamDataAccessService). It returns a tls://-prefixed address
        # outside development.
        #
        # TODO: add mTLS support when the IAM data access service exposes it.
        build_stub(::Gitlab::Iam::Update::V1::UpdateService::Stub, ::Authn::IamDataAccessService.grpc_address,
          timeout: TIMEOUT_SECONDS)
      end

      def bearer_metadata(token)
        { 'authorization' => "Bearer #{token}" }
      end
    end
  end
end
