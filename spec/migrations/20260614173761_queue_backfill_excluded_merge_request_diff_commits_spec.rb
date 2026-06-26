# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillExcludedMergeRequestDiffCommits, migration: :gitlab_main,
  feature_category: :code_review_workflow do
  let!(:batched_migration) { described_class::MIGRATION }

  describe '#up' do
    context 'on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      end

      it 'schedules a new batched migration' do
        reversible_migration do |migration|
          migration.before -> {
            expect(batched_migration).not_to have_scheduled_batched_migration
          }

          migration.after -> {
            expect(batched_migration).to have_scheduled_batched_migration(
              gitlab_schema: :gitlab_main,
              table_name: :excluded_merge_requests,
              column_name: :id,
              batch_size: described_class::BATCH_SIZE,
              sub_batch_size: described_class::SUB_BATCH_SIZE
            )
          }
        end
      end
    end

    context 'on self-managed' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(false)
      end

      it 'does not schedule the batched background migration' do
        reversible_migration do |migration|
          migration.before -> {
            expect(batched_migration).not_to have_scheduled_batched_migration
          }

          migration.after -> {
            expect(batched_migration).not_to have_scheduled_batched_migration
          }
        end
      end
    end
  end
end
