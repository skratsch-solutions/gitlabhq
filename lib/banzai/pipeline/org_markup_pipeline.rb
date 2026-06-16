# frozen_string_literal: true

module Banzai
  module Pipeline
    class OrgMarkupPipeline < BasePipeline
      def self.filters
        @filters ||= FilterArray[
          Filter::MarkupHeadingAnchorFilter,
          Filter::SanitizationFilter,
          Filter::SanitizeLinkFilter,
          Filter::CodeLanguageFilter,
          Filter::AssetProxyFilter,
          Filter::AutolinkFilter,
          Filter::ExternalLinkFilter,
          Filter::PlantumlFilter,
          Filter::KrokiFilter,
          Filter::MathFilter,
          Filter::MermaidFilter,
          Filter::HeadingAccessibilityFilter,
          Filter::SyntaxHighlightFilter # this filter should remain at the end
        ]
      end

      def self.transform_context(context)
        Filter::AssetProxyFilter.transform_context(context)
      end
    end
  end
end
