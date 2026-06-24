# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits,
  feature_category: :system_access do
  describe 'registry coverage' do
    # The labkit adapter is the only rate-limiting path; there is no legacy
    # fallback. A rate_limits key with no registry entry would not have a Labkit
    # rule to route through. This guard fails
    # loudly when a new key is added to ApplicationRateLimiter.rate_limits
    # without a matching SupportedRateLimits entry.
    it 'registers every ApplicationRateLimiter.rate_limits key' do
      rate_limit_keys = ::Gitlab::ApplicationRateLimiter.rate_limits.keys.to_set
      registered = described_class.all.keys.to_set

      unregistered = rate_limit_keys - registered

      expect(unregistered).to be_empty,
        "These ApplicationRateLimiter.rate_limits keys have no Labkit::RateLimit registry " \
          "entry, so they would not be rate limited: #{unregistered.to_a.sort.join(', ')}. " \
          "Add an entry in SupportedRateLimits (or its EE counterpart)."
    end
  end
end
