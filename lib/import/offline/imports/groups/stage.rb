# frozen_string_literal: true

module Import
  module Offline
    module Imports
      module Groups
        class Stage < ::BulkImports::Stage
          private

          def config
            {
              group: {
                pipeline: Import::Offline::Groups::Pipelines::GroupPipeline,
                stage: 0
              },
              finisher: {
                pipeline: ::BulkImports::Common::Pipelines::EntityFinisher,
                stage: 1
              }
            }
          end
        end
      end
    end
  end
end
