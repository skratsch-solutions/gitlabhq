# frozen_string_literal: true

require 'fast_spec_helper'
require 'html/pipeline'
require_relative '../../../support/shared_examples/lib/banzai/filters/filter_timeout_shared_examples'

RSpec.describe Banzai::Filter::MarkupHeadingAnchorFilter, :aggregate_failures, feature_category: :markdown do
  def filter(html, context = {})
    described_class.call(html, context)
  end

  describe 'adds heading IDs and anchor links' do
    it 'adds id and anchor to headings' do
      result = filter('<h1>Hello World</h1>')
      heading = result.at_css('h1')

      expect(heading['id']).to eq('user-content-hello-world')
      anchor = heading.at_css('a.anchor')
      expect(anchor).to be_present
      expect(anchor['href']).to eq('#hello-world')
      expect(anchor['class']).to eq('anchor')
      expect(anchor['data-heading-content']).to eq('Hello World')
      expect(anchor['aria-label']).to include("Link to heading 'Hello World'")
    end

    it 'adds id and anchor to all heading levels with correct href values' do
      result = filter(
        <<~HTML
          <h1>Heading 1</h1>
          <h2>Heading 2</h2>
          <h3>Heading 3</h3>
          <h4>Heading 4</h4>
          <h5>Heading 5</h5>
          <h6>Heading 6</h6>
          <h2>Another H2</h2>
        HTML
      )

      headings = result.css('h1, h2, h3, h4, h5, h6')
      expect(headings.size).to eq(7)
      headings.each do |heading|
        expect(heading['id']).to be_present
        expect(heading.at_css('a.anchor')).to be_present
      end

      expect(result.at_css('h1')['id']).to eq('user-content-heading-1')
      expect(result.at_css('h1 a.anchor')['href']).to eq('#heading-1')
      expect(result.at_css('h6')['id']).to eq('user-content-heading-6')
      expect(result.at_css('h6 a.anchor')['href']).to eq('#heading-6')
    end

    describe 'heading slug generation' do
      using RSpec::Parameterized::TableSyntax

      where(:heading_text, :expected_slug, :case_name) do
        [
          ['path/to/file.rb', 'pathtofilerb', 'removes non-permitted characters'],
          ['(Tips & Tricks)', 'tips--tricks', 'converts spaces to dashes'],
          ['Café', 'café', 'preserves accented characters'],
          ['日本語の見出し', '日本語の見出し', 'preserves non-Latin heading text'],
          ['!#$%&*+,./:;=?@\^`|~<>[]{}()', 'h1', 'falls back to heading name when slug would be empty']
        ]
      end

      with_them do
        it 'generates correct id and anchor href' do
          doc = Nokogiri::HTML5.fragment('<h1>')
          doc.at_css('h1').content = heading_text
          result = filter(doc)
          heading = result.at_css('h1')

          expect(heading['id']).to eq("user-content-#{expected_slug}")
          expect(heading.at_css('a.anchor')['href']).to eq("##{expected_slug}")
        end
      end
    end

    it 'handles duplicate heading slugs by appending a suffix' do
      result = filter('<h1>Foo</h1><h2>Foo</h2><h3>Foo</h3>')

      expect(result.at_css('h1')['id']).to eq('user-content-foo')
      expect(result.at_css('h1 a.anchor')['href']).to eq('#foo')
      expect(result.at_css('h2')['id']).to eq('user-content-foo-1')
      expect(result.at_css('h2 a.anchor')['href']).to eq('#foo-1')
      expect(result.at_css('h3')['id']).to eq('user-content-foo-2')
      expect(result.at_css('h3 a.anchor')['href']).to eq('#foo-2')
    end
  end

  describe 'skips headings that already have an id' do
    it 'does not modify headings with existing id' do
      result = filter('<h2 id="existing-id">Already Has ID</h2>')

      heading = result.at_css('h2')
      expect(heading['id']).to eq('existing-id')
      expect(heading.at_css('a.anchor')).to be_nil
    end
  end

  describe 'skips empty headings' do
    using RSpec::Parameterized::TableSyntax

    where(:html) do
      [
        ['<h1></h1>'],
        ['<h1>   </h1>']
      ]
    end

    with_them do
      it 'does not add id to empty headings' do
        result = filter(html)
        heading = result.at_css('h1')

        expect(heading['id']).to be_nil
        expect(heading.at_css('a.anchor')).to be_nil
      end
    end
  end

  describe 'heading text extraction' do
    it 'extracts text content ignoring HTML markup inside heading' do
      result = filter('<h1>Hello <em>World</em>!</h1>')
      heading = result.at_css('h1')

      expect(heading['id']).to eq('user-content-hello-world')
      anchor = heading.at_css('a.anchor')
      expect(anchor['href']).to eq('#hello-world')
      expect(anchor['data-heading-content']).to eq('Hello World!')
    end
  end

  it_behaves_like 'pipeline timing check'
end
