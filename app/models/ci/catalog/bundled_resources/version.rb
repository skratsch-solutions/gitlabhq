# frozen_string_literal: true

module Ci
  module Catalog
    module BundledResources
      class Version < ::ApplicationRecord
        include SemanticVersionable

        self.table_name = 'catalog_bundled_resource_versions'

        belongs_to :bundled_resource, class_name: 'Ci::Catalog::BundledResource',
          foreign_key: :catalog_bundled_resource_id, inverse_of: :versions, optional: false
        has_many :components, class_name: 'Ci::Catalog::BundledResources::Component',
          foreign_key: :catalog_bundled_version_id, inverse_of: :version

        validates :semver_prerelease, length: { maximum: 255 }
      end
    end
  end
end
