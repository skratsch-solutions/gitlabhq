# frozen_string_literal: true

require 'redis'

module Gitlab
  module Peek
    module RedisInstrumented
      def call(*args, &block)
        start = Time.now
        super(*args, &block)
      ensure
        duration = (Time.now - start)
        add_call_details(duration, args)
      end

      private

      def add_call_details(duration, args)
        # redis-rb passes an array (e.g. [:get, key])
        return unless args.length == 1

        detail_store << {
          cmd: args.first,
          duration: duration,
          backtrace: Gitlab::Profiler.clean_backtrace(caller)
        }
      end

      def detail_store
        ::Gitlab::SafeRequestStore['redis_call_details'] ||= []
      end
    end
  end
end

module Peek
  module Views
    class RedisDetailed < DetailedView
      REDACTED_MARKER = "<redacted>"

      def key
        'redis'
      end

      def detail_store
        ::Gitlab::SafeRequestStore['redis_call_details'] ||= []
      end

      private

      def duration
        detail_store.map { |entry| entry[:duration] }.sum # rubocop:disable CodeReuse/ActiveRecord
      end

      def calls
        detail_store.count
      end

      def call_details
        detail_store
      end

      def format_call_details(call)
        call.merge(cmd: format_command(call[:cmd]),
                   duration: (call[:duration] * 1000).round(3))
      end

      def format_command(cmd)
        if cmd.length >= 2 && cmd.first =~ /^auth$/i
          cmd[-1] = REDACTED_MARKER
        # Scrub out the value of the SET calls to avoid binary
        # data or large data from spilling into the view
        elsif cmd.length >= 3 && cmd.first =~ /set/i
          cmd[2..-1] = REDACTED_MARKER
        end

        cmd.join(' ')
      end
    end
  end
end

class Redis::Client
  prepend Gitlab::Peek::RedisInstrumented
end
