# frozen_string_literal: true

module Banzai
  module Filter
    # Adds heading IDs and anchor links to markup content (Org-mode, etc.)
    # that don't natively generate them.
    # This enables the table of contents navigation in the blob viewer.
    #
    # Input (org-ruby output):
    #   <h1>My Heading</h1>
    #
    # Output:
    #   <h1 id="user-content-my-heading">My Heading<a class="anchor" href="#my-heading"></a></h1>
    #
    # - Heading ids are prefixed with `user-content-`; SanitizationFilter strips ids without it.
    # - The anchor <a> needs class=anchor; SanitizationFilter strips <a> tags without it.
    # - The anchor's href omits the prefix to match Markdown behavior;
    #   JavaScript (handleLocationHash) resolves the resulting id/href mismatch.
    class MarkupHeadingAnchorFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      HEADER_CSS = 'h1, h2, h3, h4, h5, h6'
      HEADER_XPATH = Gitlab::Utils::Nokogiri.css_to_xpath(HEADER_CSS).freeze

      def call
        used_slugs = {}

        doc.xpath(HEADER_XPATH).each do |heading|
          annotate_heading(heading, used_slugs, doc)
        end

        doc
      end

      private

      def annotate_heading(heading, used_slugs, doc)
        return if heading.has_attribute?('id')

        text_content = heading.text.strip
        return if text_content.blank?

        slug = generate_unique_slug(text_content, heading.name, used_slugs)
        full_id = "#{Banzai::Renderer::USER_CONTENT_ID_PREFIX}#{slug}"
        heading.set_attribute('id', full_id)

        anchor = Nokogiri::XML::Node.new('a', doc)
        anchor.set_attribute('class', 'anchor')
        anchor.set_attribute('href', "##{slug}")
        anchor.set_attribute('aria-label', "Link to heading '#{text_content}'")
        anchor.set_attribute('data-heading-content', text_content)
        heading.add_child(anchor)
      end

      def generate_unique_slug(text, heading_name, used_slugs)
        base_slug = ActiveSupport::Inflector.parameterize(text)
        # Non-ASCII headings produce blank slugs. Use tag name as a fallback.
        base_slug = heading_name if base_slug.blank?

        if used_slugs.key?(base_slug)
          used_slugs[base_slug] += 1
          "#{base_slug}-#{used_slugs[base_slug]}"
        else
          used_slugs[base_slug] = 0
          base_slug
        end
      end
    end
  end
end
