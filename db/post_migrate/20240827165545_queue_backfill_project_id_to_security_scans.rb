# frozen_string_literal: true

class QueueBackfillProjectIdToSecurityScans < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillProjectIdToSecurityScans"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :security_scans,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :security_scans, :id, [])
  end
end
