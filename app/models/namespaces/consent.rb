# frozen_string_literal: true

module Namespaces
  class Consent < ApplicationRecord
    self.table_name = 'namespaces_consents'

    belongs_to :namespace
    # user_id is nullified asynchronously via loose foreign key on user deletion
    belongs_to :user, optional: true

    # NOTE: use new consecutive integer values for new features.
    # Do not reuse removed values to avoid false-positive consent matches.
    enum :feature_name, {
      code_review_flow_dap_routing: 1
    }

    validates :namespace, presence: true
    validates :feature_name, presence: true, uniqueness: { scope: :namespace_id }
    validates :user_id, presence: true, on: :create

    def readonly?
      persisted?
    end
  end
end
