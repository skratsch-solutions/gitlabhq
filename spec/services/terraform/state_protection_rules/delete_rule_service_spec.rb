# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateProtectionRules::DeleteRuleService, '#execute',
  feature_category: :infrastructure_as_code do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be_with_refind(:protection_rule) do
    create(:terraform_state_protection_rule, project: project, state_name: 'production')
  end

  let(:current_user) { maintainer }

  subject(:service_execute) { described_class.new(protection_rule, current_user: current_user).execute }

  shared_examples 'a successful service response' do
    it 'returns success' do
      result = service_execute
      expect(result).to be_success
      expect(result.payload[:terraform_state_protection_rule]).to eq(protection_rule)
    end

    it 'deletes the rule' do
      service_execute
      expect { protection_rule.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  shared_examples 'an erroneous service response' do |message: nil|
    it 'returns error' do
      result = service_execute
      expect(result).to be_error
      expect(result.message).to include(*Array(message)) if message
      expect(result.payload[:terraform_state_protection_rule]).to be_nil
    end

    it 'does not delete the rule' do
      expect { service_execute }.not_to change { Terraform::StateProtectionRule.count }
      expect { protection_rule.reload }.not_to raise_error
    end
  end

  it_behaves_like 'a successful service response'

  context 'when error occurs during delete operation' do
    before do
      allow(protection_rule).to receive(:destroy).and_return(false)
      allow(protection_rule).to receive_message_chain(:errors, :full_messages).and_return(['Some error'])
    end

    it_behaves_like 'an erroneous service response', message: 'Some error'
  end

  context 'when current user does not have permission' do
    let_it_be(:developer) { create(:user, developer_of: project) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }
    let_it_be(:guest) { create(:user, guest_of: project) }
    let_it_be(:anonymous) { create(:user) }

    where(:current_user) do
      [ref(:developer), ref(:reporter), ref(:guest), ref(:anonymous)]
    end

    with_them do
      it_behaves_like 'an erroneous service response',
        message: 'Unauthorized to delete a terraform state protection rule'
    end
  end

  context 'without protection_rule' do
    it 'raises ArgumentError' do
      expect { described_class.new(nil, current_user: current_user) }
        .to raise_error(ArgumentError)
    end
  end

  context 'without current_user' do
    it 'raises ArgumentError' do
      expect { described_class.new(protection_rule, current_user: nil) }
        .to raise_error(ArgumentError)
    end
  end
end
