# frozen_string_literal: true

class RequeueBackfillFindingIdInVulnerabilities3 < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  MIGRATION = "BackfillFindingIdInVulnerabilities"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    Gitlab::Database::QueryAnalyzers::Base.suppress_schema_issues_for_decomposed_tables do
      delete_batched_background_migration(
        MIGRATION,
        :vulnerabilities,
        :id,
        []
      )

      queue_batched_background_migration(
        MIGRATION,
        :vulnerabilities,
        :id,
        job_interval: DELAY_INTERVAL,
        batch_size: BATCH_SIZE,
        sub_batch_size: SUB_BATCH_SIZE
      )
    end
  end

  def down
    Gitlab::Database::QueryAnalyzers::Base.suppress_schema_issues_for_decomposed_tables do
      delete_batched_background_migration(MIGRATION, :vulnerabilities, :id, [])
    end
  end
end
