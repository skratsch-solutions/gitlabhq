# frozen_string_literal: true

module Ci
  module Catalog
    module BundledResources
      class Component < ::ApplicationRecord
        self.table_name = 'catalog_bundled_resource_components'

        belongs_to :bundled_resource, class_name: 'Ci::Catalog::BundledResource',
          foreign_key: :catalog_bundled_resource_id, inverse_of: :components, optional: false
        belongs_to :version, class_name: 'Ci::Catalog::BundledResources::Version',
          foreign_key: :catalog_bundled_version_id, inverse_of: :components, optional: false

        validates :name, presence: true, length: { maximum: 255 },
          uniqueness: { scope: :catalog_bundled_version_id }
        validates :spec, json_schema: { filename: 'catalog_resource_component_spec', size_limit: 64.kilobytes }
      end
    end
  end
end
