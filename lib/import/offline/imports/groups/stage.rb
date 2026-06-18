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
              max_iids: {
                pipeline: ::BulkImports::Common::Pipelines::MaxIidsPipeline,
                stage: 1
              },
              namespace_settings: {
                pipeline: ::BulkImports::Groups::Pipelines::NamespaceSettingsPipeline,
                stage: 1
              },
              labels: {
                pipeline: ::BulkImports::Common::Pipelines::LabelsPipeline,
                stage: 1
              },
              milestones: {
                pipeline: ::BulkImports::Common::Pipelines::MilestonesPipeline,
                stage: 1
              },
              boards: {
                pipeline: ::BulkImports::Common::Pipelines::BoardsPipeline,
                stage: 2
              },
              uploads: {
                pipeline: ::BulkImports::Common::Pipelines::UploadsPipeline,
                stage: 2
              },
              # UserContributionsPipeline updates source users created by the
              # preceding relation pipelines. It must run after all relation
              # pipelines.
              user_contributions: {
                pipeline: Import::Offline::Common::Pipelines::UserContributionsPipeline,
                stage: 3
              },
              subgroups: {
                pipeline: Import::Offline::Groups::Pipelines::SubgroupEntitiesPipeline,
                stage: 3 # SubGroup Entities must be imported in later stage
                # to Project Entities to avoid `full_path` naming conflicts.
                # TODO: ProjectEntitiesPipeline to be added in https://gitlab.com/gitlab-org/gitlab/-/work_items/538351
              },
              finisher: {
                pipeline: ::BulkImports::Common::Pipelines::EntityFinisher,
                stage: 4
              }
            }
          end
        end
      end
    end
  end
end
