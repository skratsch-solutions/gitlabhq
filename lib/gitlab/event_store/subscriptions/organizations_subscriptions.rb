# frozen_string_literal: true

module Gitlab
  module EventStore
    module Subscriptions
      class OrganizationsSubscriptions < BaseSubscriptions
        def register
          # Subscribers for Organizations::ConfirmedEvent will be added here.
          # See: https://gitlab.com/gitlab-org/gitlab/-/work_items/597856
        end
      end
    end
  end
end
