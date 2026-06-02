# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::OrgMarkupPipeline, feature_category: :wiki do
  it_behaves_like 'sanitize pipeline'

  describe '.filters' do
    it 'adds autolinking without changing the generic markup pipeline', :aggregate_failures do
      expect(described_class.filters).to include(Banzai::Filter::AutolinkFilter)
      expect(Banzai::Pipeline::MarkupPipeline.filters).not_to include(Banzai::Filter::AutolinkFilter)
    end
  end

  it 'resolves from the org_markup pipeline name' do
    expect(Banzai::Pipeline[:org_markup]).to eq(described_class)
  end

  it 'autolinks bare URLs', :aggregate_failures do
    output = described_class.to_html('See https://example.com for details.', pipeline: :org_markup)
    link = Nokogiri::HTML.fragment(output).at_css('a')

    expect(link[:href]).to eq('https://example.com')
    expect(link.text).to eq('https://example.com')
  end

  it 'leaves text without URLs unchanged' do
    input = 'This text contains no links to autolink.'

    expect(described_class.to_html(input, pipeline: :org_markup)).to eq(input)
  end

  it 'sanitizes potentially malicious HTML', :aggregate_failures do
    output = described_class.to_html('<script>alert(1)</script>', pipeline: :org_markup)
    document = Nokogiri::HTML.fragment(output)

    expect(document.at_css('script')).to be_nil
    expect(output).not_to include('<script>')
  end
end
