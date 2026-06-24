# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    class FeatureMatchService
      VALID_PANELS = %w[project group].freeze
      MIN_QUERY_LENGTH = 2

      def initialize(query:, panel:)
        @query = query
        @panel = panel.to_s
      end

      def execute
        return [] unless VALID_PANELS.include?(@panel)

        ranked_entries(normalize(@query))
          .map { |e| e['feature_key'] } # rubocop:disable Rails/Pluck -- entries is a plain Array, not an ActiveRecord relation
          .uniq
      end

      private

      def normalize(query)
        query.to_s.downcase.strip
      end

      # Returns entries matching the query, filtered to the requested panel,
      # ranked: exact term match, then prefix, then substring.
      def ranked_entries(normalized_query)
        return [] if normalized_query.length < MIN_QUERY_LENGTH

        exact = []
        starts = []
        contains = []

        Onboarding::FeatureLibrary::TerminologyMap.all.each do |entry| # rubocop:disable Rails/FindEach -- iterating a frozen Array, not an ActiveRecord relation
          next unless Array(entry['panels']).include?(@panel)

          term = entry['term']
          next unless term.include?(normalized_query)

          if term == normalized_query
            exact << entry
          elsif term.start_with?(normalized_query)
            starts << entry
          else
            contains << entry
          end
        end

        (exact + starts + contains)
      end
    end
  end
end
