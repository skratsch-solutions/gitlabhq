# frozen_string_literal: true

ActiveContext.configure do |config|
  config.enabled = true
  config.indexing_enabled = true
  config.logger = ::Gitlab::ActiveContext::Logger.build

  # The flag exists for multi-version compatibility: mixing FIFO and time-based
  # scores in one queue can lose items, so enable it only once every node runs
  # this code (doc/development/multi_version_compatibility.md). This block is
  # re-evaluated on every read, so flipping the flag needs no restart; the
  # rescue turns unexpected Feature errors into "delay off" instead of
  # breaking queue operations.
  config.retry_queue_delay_enabled = begin
    Feature.enabled?(:active_context_retry_queue_delay, :instance, type: :ops)
  rescue StandardError
    false
  end

  config.queue_classes = []
  if Gitlab.ee?
    config.queue_classes.concat([
      ::Ai::ActiveContext::Queues::Code,
      ::Ai::ActiveContext::Queues::CodeBackfill
    ])
  end
end
