# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Mcp::Logger, feature_category: :mcp_server do
  describe '.file_name_noext' do
    it { expect(described_class.file_name_noext).to eq('mcp') }
  end
end
