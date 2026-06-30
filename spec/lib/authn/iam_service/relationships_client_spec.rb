# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::RelationshipsClient, feature_category: :system_access do
  subject(:client) { described_class.new }

  describe '#assign_role' do
    let(:organization_uuid) { Gitlab::Utils.uuid_v7 }
    let(:user_id) { 2 }
    let(:resource_id) { '019ed9d4-0000-7000-8000-000000000000' }
    let(:role_id) { Gitlab::Utils.uuid_v7 }
    let(:token) { 'ar-token' }

    it 'writes a single ASSIGNMENT tuple scoped to the org and built from the given pieces',
      :aggregate_failures do
      expect(client).to receive(:write_relationships) do |inputs, org_id:, token:|
        expect(token).to eq('ar-token')
        expect(org_id).to eq(organization_uuid)
        expect(inputs.size).to eq(1)

        input = inputs.first
        expect(input.subject.identity.origin).to eq(:ORIGIN_ORGANIZATION)
        expect(input.subject.identity.origin_id).to eq(organization_uuid)
        expect(input.subject.identity.local_id).to eq(user_id.to_s)
        expect(input.object.id).to eq(resource_id)
        expect(input.kind).to eq(:KIND_ASSIGNMENT)
        expect(input.role.id).to eq(role_id)

        ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
      end

      client.assign_role(
        organization_uuid: organization_uuid,
        user_id: user_id,
        resource_id: resource_id,
        role_id: role_id,
        token: token
      )
    end
  end

  describe 'insecure channel guard' do
    it 'refuses an insecure channel outside development and test' do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
      allow(Authn::IamDataAccessService).to receive(:grpc_address).and_return('localhost:5005')

      expect { client.write_relationships([], org_id: 'org-uuid', token: 'tok') }
        .to raise_error(Authn::IamService::BaseClient::InsecureChannelError)
    end
  end
end
