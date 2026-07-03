# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::RelationshipsClient, feature_category: :system_access do
  subject(:client) { described_class.new }

  describe '#assign_roles' do
    let(:organization_uuid) { Gitlab::Utils.uuid_v7 }
    let(:resource_id) { '019ed9d4-0000-7000-8000-000000000000' }
    let(:other_resource_id) { '019ed9d4-0000-7000-8000-000000000001' }
    let(:role_id) { Gitlab::Utils.uuid_v7 }
    let(:token) { 'ar-token' }
    let(:assignments) do
      [
        { assignee_id: 2, resource_id: resource_id, role_id: role_id },
        { assignee_id: 3, resource_id: other_resource_id, role_id: role_id }
      ]
    end

    it 'writes one ASSIGNMENT tuple per assignment, all scoped to the org', :aggregate_failures do
      expect(client).to receive(:write_relationships) do |inputs, token:|
        expect(token).to eq('ar-token')
        expect(inputs.size).to eq(2)
        expect(inputs.map { |i| i.subject.identity.origin }).to all(eq(:ORIGIN_ORGANIZATION))
        expect(inputs.map { |i| i.subject.identity.origin_id }).to all(eq(organization_uuid))
        expect(inputs.map { |i| [i.subject.identity.local_id, i.object.id] })
          .to match_array([['2', resource_id], ['3', other_resource_id]])
        expect(inputs.map(&:kind)).to all(eq(:KIND_ASSIGNMENT))
        expect(inputs.map { |i| i.role.id }).to all(eq(role_id))

        ::Gitlab::Iam::Update::V1::WriteRelationshipsResponse.new
      end

      client.assign_roles(assignments, organization_uuid: organization_uuid, token: token)
    end
  end

  describe 'insecure channel guard' do
    it 'refuses an insecure channel outside development and test' do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
      allow(Authn::IamDataAccessService).to receive(:grpc_address).and_return('localhost:5005')

      expect { client.write_relationships([], token: 'tok') }
        .to raise_error(Authn::IamService::BaseClient::InsecureChannelError)
    end
  end
end
