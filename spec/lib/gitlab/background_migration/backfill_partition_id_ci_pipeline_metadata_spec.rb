# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPartitionIdCiPipelineMetadata,
  feature_category: :continuous_integration do
  let(:ci_pipelines_table) { table(:ci_pipelines, database: :ci) }
  let(:ci_pipeline_metadata_table) { table(:ci_pipeline_metadata, database: :ci) }
  let!(:pipeline_100) { ci_pipelines_table.create!(id: 1, partition_id: 100) }
  let!(:pipeline_101) { ci_pipelines_table.create!(id: 2, partition_id: 101) }
  let!(:pipeline_102) { ci_pipelines_table.create!(id: 3, partition_id: 100) }
  let!(:ci_pipeline_metadata_100) do
    ci_pipeline_metadata_table.create!(
      pipeline_id: pipeline_100.id,
      project_id: 1,
      partition_id: pipeline_100.partition_id
    )
  end

  let!(:ci_pipeline_metadata_101) do
    ci_pipeline_metadata_table.create!(
      pipeline_id: pipeline_101.id,
      project_id: 1,
      partition_id: pipeline_101.partition_id
    )
  end

  let!(:invalid_ci_pipeline_metadata) do
    ci_pipeline_metadata_table.create!(
      pipeline_id: pipeline_102.id,
      project_id: 1,
      partition_id: pipeline_102.partition_id
    )
  end

  let(:migration_attrs) do
    {
      start_id: ci_pipeline_metadata_table.minimum(:pipeline_id),
      end_id: ci_pipeline_metadata_table.maximum(:pipeline_id),
      batch_table: :ci_pipeline_metadata,
      batch_column: :pipeline_id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection
    }
  end

  let!(:migration) { described_class.new(**migration_attrs) }
  let(:connection) { Ci::ApplicationRecord.connection }

  around do |example|
    connection.transaction do
      connection.execute(<<~SQL)
        ALTER TABLE ci_pipelines DISABLE TRIGGER ALL;
      SQL

      example.run

      connection.execute(<<~SQL)
        ALTER TABLE ci_pipelines ENABLE TRIGGER ALL;
      SQL
    end
  end

  describe '#perform' do
    context 'when second partition does not exist' do
      it 'does not execute the migration' do
        expect { migration.perform }
          .not_to change { invalid_ci_pipeline_metadata.reload.partition_id }
      end
    end

    context 'when second partition exists' do
      before do
        allow(migration).to receive(:uses_multiple_partitions?).and_return(true)
        pipeline_102.update!(partition_id: 101)
      end

      it 'fixes invalid records in the wrong the partition' do
        expect { migration.perform }
          .to not_change { ci_pipeline_metadata_100.reload.partition_id }
          .and not_change { ci_pipeline_metadata_101.reload.partition_id }
          .and change { invalid_ci_pipeline_metadata.reload.partition_id }
          .from(100)
          .to(101)
      end
    end
  end
end
