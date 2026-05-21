# frozen_string_literal: true

require 'rainbow'

require_relative 'env'

module Gitlab
  module PrinciplesDistiller
    # Process-wide pointer to the repository workspace. Set via
    # `Workspace.path = ...` (typically by the bin scripts honoring
    # `--workspace`), or falls back to `$CI_PROJECT_DIR`.
    module Workspace
      class << self
        attr_writer :path

        def path
          @path || ENV.fetch(Env::CI_PROJECT_DIR) do
            abort Rainbow('ERROR: workspace path not set. Pass --workspace, set CI_PROJECT_DIR, ' \
              'or call Gitlab::PrinciplesDistiller::Workspace.path = ...').red
          end
        end

        def join(*segments)
          File.join(path, *segments)
        end
      end
    end
  end
end
