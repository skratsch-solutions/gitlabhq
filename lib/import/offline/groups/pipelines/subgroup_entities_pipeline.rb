# frozen_string_literal: true

module Import
  module Offline
    module Groups
      module Pipelines
        class SubgroupEntitiesPipeline
          include ::BulkImports::Pipeline
          include ::BulkImports::Pipeline::HexdigestCacheStrategy

          transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer
          transformer ::BulkImports::Groups::Transformers::SubgroupToEntityTransformer

          def extract(context)
            configuration = context.offline_configuration

            prefix = "#{context.entity.source_full_path}/"

            subgroups = configuration.entity_prefix_mapping.filter_map do |full_path, entity_prefix|
              next unless full_path.start_with?(prefix)
              next unless entity_prefix.start_with?('group_')

              path = full_path.delete_prefix(prefix)

              next if path.include?('/')
              next if path.empty?

              { full_path: full_path, path: path }.with_indifferent_access
            end

            ::BulkImports::Pipeline::ExtractedData.new(data: subgroups)
          end

          def load(context, data)
            context.bulk_import.entities.create!(data)
          end
        end
      end
    end
  end
end
