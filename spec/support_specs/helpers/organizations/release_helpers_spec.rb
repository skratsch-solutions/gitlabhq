# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ReleaseHelpers, feature_category: :organization do
  let(:stage) { ::Organizations::Release::Stage::BY_KEY[:experimental] }
  let(:registered_flag) do
    ::Organizations::Release::Flag.new(name: 'demo_flag', description: 'For specs', stage: stage)
  end

  before do
    allow(::Organizations::Release::Registry.instance)
      .to receive(:find).with(:demo_flag).and_return(registered_flag)
  end

  describe '#stub_organization_release' do
    it 'enables the backing stage flag' do
      stub_organization_release(:demo_flag, enabled: true)

      expect(::Organizations::Release.enabled?(:demo_flag, nil)).to be(true)
    end

    it 'disables the backing stage flag' do
      stub_organization_release(:demo_flag, enabled: false)

      expect(::Organizations::Release.enabled?(:demo_flag, nil)).to be(false)
    end

    it 'raises UnknownFlagError for an unknown flag' do
      allow(::Organizations::Release::Registry.instance)
        .to receive(:find).with(:unknown_flag).and_call_original

      expect { stub_organization_release(:unknown_flag, enabled: true) }
        .to raise_error(::Organizations::Release::UnknownFlagError)
    end
  end
end
