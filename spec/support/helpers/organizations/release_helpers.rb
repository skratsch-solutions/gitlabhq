# frozen_string_literal: true

module Organizations
  module ReleaseHelpers
    # Toggles a logical Organizations release flag in specs by stubbing whichever
    # shared stage flag currently backs it (resolved through the registry in
    # config/organizations_release.yml), so specs do not hard-code the stage a
    # feature happens to sit at. When the feature advances to another stage the
    # spec keeps testing the right flag.
    #
    # Disabling a flag disables its whole stage, which mirrors how the shared
    # stage flags behave in production.
    def stub_organization_release(flag, enabled:)
      stage_flag = ::Organizations::Release::Registry.instance.find(flag).stage.flag

      stub_feature_flags(stage_flag => enabled)
    end
  end
end

RSpec.configure do |config|
  config.include Organizations::ReleaseHelpers
end
