# frozen_string_literal: true

# Contract shared by every Gitlab::PolicyStore::Ports::PolicyRepository
# implementation. Any adapter (in-memory today, a remote client later) must
# satisfy it, which is what guarantees they are interchangeable behind the
# facade.
#
# Requires the including context to define:
#   - `repository`        the adapter under test
#   - `organization_id`   a valid organization id
RSpec.shared_examples 'a policy repository' do
  let(:non_existing_id) { -1 }

  let(:attributes) do
    {
      organization_id: organization_id,
      name: 'My approval policy',
      trigger_id: 'merge_request',
      rules: { 'rules' => [{ 'type' => 'scan_finding' }] },
      actions: [{ 'type' => 'require_approval' }],
      policy_scope: { 'compliance_frameworks' => [] },
      scope_rego: 'package gitlab.policy.scope',
      mode: 'audit',
      lifecycle_state: 'active'
    }
  end

  describe '#store' do
    it 'persists the policy and returns a Gitlab::PolicyStore::Policy' do
      policy = repository.store(attributes)

      expect(policy).to be_a(Gitlab::PolicyStore::Policy)
      expect(policy).to have_attributes(
        id: be_truthy,
        organization_id: organization_id,
        name: 'My approval policy',
        trigger_id: 'merge_request',
        rules: { 'rules' => [{ 'type' => 'scan_finding' }] },
        actions: [{ 'type' => 'require_approval' }],
        scope_rego: 'package gitlab.policy.scope',
        mode: 'audit',
        lifecycle_state: 'active'
      )
    end
  end

  describe '#find' do
    it 'returns the previously stored policy' do
      stored = repository.store(attributes)

      expect(repository.find(stored.id)).to eq(stored)
    end

    it 'raises Gitlab::PolicyStore::NotFound when the policy does not exist' do
      expect { repository.find(non_existing_id) }.to raise_error(Gitlab::PolicyStore::NotFound)
    end
  end

  describe '#list' do
    it 'returns the policies for the organization' do
      stored = repository.store(attributes)

      expect(repository.list(organization_id: organization_id)).to contain_exactly(stored)
    end
  end
end
