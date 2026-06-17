# frozen_string_literal: true

module Gitlab
  module Mcp
    class Logger < ::Gitlab::JsonLogger
      def self.file_name_noext
        'mcp'
      end
    end
  end
end
