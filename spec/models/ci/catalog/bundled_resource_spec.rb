# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::BundledResource, feature_category: :pipeline_composition do
  describe 'associations' do
    it { is_expected.to have_many(:versions).class_name('Ci::Catalog::BundledResources::Version') }
    it { is_expected.to have_many(:components).class_name('Ci::Catalog::BundledResources::Component') }
  end

  describe 'validations' do
    subject { build(:ci_catalog_bundled_resource) }

    it { is_expected.to validate_presence_of(:server_fqdn) }
    it { is_expected.to validate_presence_of(:full_path) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:server_fqdn).is_at_most(255) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:full_path).is_at_most(1024) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { is_expected.to validate_uniqueness_of(:full_path).scoped_to(:server_fqdn).case_insensitive }
  end

  describe 'case-insensitive natural key' do
    it 'rejects a resource differing only by case in server_fqdn or full_path' do
      create(:ci_catalog_bundled_resource, server_fqdn: 'gitlab.com', full_path: 'gitlab-org/components/foo')

      expect do
        create(:ci_catalog_bundled_resource, server_fqdn: 'GitLab.com', full_path: 'GitLab-Org/Components/Foo')
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
