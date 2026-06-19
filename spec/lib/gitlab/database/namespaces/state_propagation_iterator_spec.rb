# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Namespaces::StatePropagationIterator, feature_category: :groups_and_projects do
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be_with_reload(:subgroup1) { create(:group, parent: group) }
  let_it_be_with_reload(:subgroup2) { create(:group, parent: group) }
  let_it_be(:subsubgroup1) { create(:group, parent: subgroup1) }
  let_it_be(:subsubgroup2) { create(:group, parent: subgroup1) }
  let_it_be(:project1) { create(:project, namespace: subsubgroup1) }
  let_it_be(:project2) { create(:project, namespace: subgroup2) }
  let_it_be(:project3) { create(:project, namespace: subsubgroup2) }

  let(:namespace_id) { group.id }
  let(:state_filter) { [:ancestor_inherited] }
  let(:cursor) { { current_id: namespace_id, depth: [namespace_id] } }

  def collected_ids
    [].tap do |ids|
      described_class.new(
        namespace_class: Namespace,
        cursor: cursor,
        state_filter: state_filter
      ).each_batch(of: 3) do |batch_ids|
        ids.concat(batch_ids)
      end
    end
  end

  describe '#each_batch' do
    context 'when a subgroup is in a non-overwritable state' do
      before do
        subgroup2.update!(state: :archived)
      end

      it 'prunes the subgroup and all of its descendants from the traversal' do
        expect(collected_ids).to eq([
          group.id,
          subgroup1.id,
          subsubgroup1.id,
          project1.project_namespace_id,
          subsubgroup2.id,
          project3.project_namespace_id
        ])
      end
    end

    context 'when the first child by id is in a non-overwritable state' do
      before do
        subgroup1.update!(state: :archived)
      end

      it 'prunes the first child and its descendants while still visiting later siblings' do
        expect(collected_ids).to eq([
          group.id,
          subgroup2.id,
          project2.project_namespace_id
        ])
      end
    end

    context 'when the root namespace is not in the state_filter' do
      before do
        group.update!(state: :archived)
      end

      it 'does not yield the root' do
        expect(collected_ids).to be_empty
      end
    end

    context 'when the filter accepts multiple states' do
      let(:state_filter) { [:ancestor_inherited, :archived] }

      before do
        subgroup2.update!(state: :archived)
      end

      it 'includes namespaces whose state matches any value in the filter' do
        expect(collected_ids).to eq([
          group.id,
          subgroup1.id,
          subsubgroup1.id,
          project1.project_namespace_id,
          subsubgroup2.id,
          project3.project_namespace_id,
          subgroup2.id,
          project2.project_namespace_id
        ])
      end
    end
  end
end
