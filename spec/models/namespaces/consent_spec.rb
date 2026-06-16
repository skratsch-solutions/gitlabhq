# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Consent, feature_category: :groups_and_projects do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:user) { create(:user) }

  subject(:consent) { build(:namespaces_consent, namespace: namespace, user: user) }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:parent) { create(:user) }
    let!(:model)  { create(:namespaces_consent, user: parent) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }
    it { is_expected.to validate_presence_of(:feature_name) }
    it { is_expected.to validate_presence_of(:user_id).on(:create) }

    it 'is valid with valid attributes' do
      expect(consent).to be_valid
    end

    context 'for uniqueness of feature_name per namespace' do
      before do
        create(:namespaces_consent, namespace: namespace, user: user, feature_name: :code_review_flow_dap_routing)
      end

      it 'is invalid when the same feature_name already exists for the namespace' do
        duplicate = build(:namespaces_consent, namespace: namespace, user: user,
          feature_name: :code_review_flow_dap_routing)
        expect(duplicate).to be_invalid
        expect(duplicate.errors[:feature_name]).to be_present
      end

      it 'is valid for a different namespace' do
        other_namespace = create(:namespace)
        other_consent = build(:namespaces_consent, namespace: other_namespace, user: user,
          feature_name: :code_review_flow_dap_routing)
        expect(other_consent).to be_valid
      end
    end
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:feature_name).with_values(code_review_flow_dap_routing: 1) }
  end

  describe '#readonly?' do
    it 'returns false for a new record' do
      expect(consent).not_to be_readonly
    end

    it 'returns true for a persisted record' do
      consent.save!

      expect(consent).to be_readonly
    end
  end
end
