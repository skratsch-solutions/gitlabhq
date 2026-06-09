# frozen_string_literal: true

require_relative '../../tooling/danger/post_deployment_migration_lock'

module Danger
  class PostDeploymentMigrationLock < ::Danger::Plugin
    include Tooling::Danger::PostDeploymentMigrationLock
  end
end
