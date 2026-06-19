# frozen_string_literal: true

module IssueLinks
  class CreateService < IssuableLinks::CreateService
    include IncidentManagement::UsageData
    include Gitlab::Utils::StrongMemoize

    def success(...)
      GraphqlTriggers.work_item_updated(issuable)
      super
    end

    def linkable_issuables(issues)
      @linkable_issuables ||= issues.select { |issue| can?(current_user, :admin_issue_link, issue) }
    end

    def previous_related_issuables
      @related_issues ||= issuable.related_issues(authorize: false).to_a
    end

    private

    def readonly_issuables
      referenced_issuables.select { |issuable| issuable.readable_by?(current_user) }
    end
    strong_memoize_attr :readonly_issuables

    def track_event
      track_incident_action(current_user, issuable, :incident_relate)
    end

    def link_class
      IssueLink
    end

    def extractor_context
      issuable.group_level? ? { group: issuable.namespace } : {}
    end
  end
end

IssueLinks::CreateService.prepend_mod
