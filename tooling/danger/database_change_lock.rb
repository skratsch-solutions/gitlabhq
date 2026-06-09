# frozen_string_literal: true

require_relative 'database_change_lock_window'

module Tooling
  module Danger
    module DatabaseChangeLock
      # DatabaseChangeLockWindow provides the same "find the active or upcoming lock entry"
      # logic used by the sub-plugins. The dispatcher needs the same view of which lock entry
      # is relevant so that warning-period dispatch matches the sub-plugins' own behavior.
      include DatabaseChangeLockWindow

      DEFAULT_BLOCK_LEVEL = 'only_ddl'

      LOCK_TYPE = {
        'only_ddl' => %i[database_upgrade_ddl_lock],
        'only_pdm' => %i[post_deployment_migration_lock]
      }.freeze

      def check_database_lock_contention
        return unless config_file_exists? && config_valid?

        plugins_for(config['block_level'].to_s).each do |accessor|
          danger_plugin(accessor).check_database_lock
        end
      end

      private

      def plugins_for(block_level)
        LOCK_TYPE.fetch(block_level, LOCK_TYPE.fetch(DEFAULT_BLOCK_LEVEL))
      end

      def danger_plugin(accessor)
        public_send(accessor) # rubocop:disable GitlabSecurity/PublicSend -- accessor is restricted to LOCK_TYPE values
      end
    end
  end
end
