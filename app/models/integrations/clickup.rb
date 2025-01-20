# frozen_string_literal: true

module Integrations
  class Clickup < Integration
    include Base::IssueTracker
    include HasIssueTrackerFields
    include HasAvatar

    validates :project_url, :issues_url, presence: true, public_url: true, if: :activated?

    def reference_pattern(*)
      @reference_pattern ||= /(?:(?:#|CU-)(?<issue>[a-z0-9]+)|(?<issue>[A-Z0-9_]{2,10}-\d+))\b/
    end

    def self.title
      'ClickUp'
    end

    def self.description
      s_("IssueTracker|Use Clickup as this project's issue tracker.")
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/clickup.md',
        s_("IssueTracker|Use ClickUp as this project's issue tracker.")
      )
    end

    def self.to_param
      'clickup'
    end

    def self.fields
      super.select { %w[project_url issues_url].include?(_1.name) }
    end
  end
end
