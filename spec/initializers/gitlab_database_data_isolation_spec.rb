# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitlab Organization Data Isolation', feature_category: :organization do
  let_it_be(:isolated_organization) { create(:organization, :isolated) }
  let_it_be(:other_organization) { create(:organization) }

  before do
    stub_current_organization(isolated_organization)
  end

  context 'when sharded by organization_id' do
    let_it_be(:group_isolated) { create(:group, organization: isolated_organization) }
    let_it_be(:group_other) { create(:group, organization: other_organization) }

    it 'returns only the current organization' do
      expect(Group.all.map(&:organization)).to contain_exactly(isolated_organization)
    end
  end

  context 'when sharded by user_id' do
    let_it_be(:user_isolated) { create(:user, organization: isolated_organization) }
    let_it_be(:user_other) { create(:user, organization: other_organization) }

    it 'returns only the current organization' do
      expect(UserDetail.all.map(&:user)).to contain_exactly(user_isolated)
    end
  end
end
