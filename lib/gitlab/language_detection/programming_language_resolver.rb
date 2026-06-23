# frozen_string_literal: true

module Gitlab
  # rubocop:disable Gitlab/NamespacedClass -- Gitlab::LanguageDetection is the existing namespace for this workflow.
  class LanguageDetection
    class ProgrammingLanguageResolver
      def initialize(detected_languages)
        @detected_languages = detected_languages
      end

      def execute
        existing_languages + created_languages
      end

      private

      attr_reader :detected_languages

      def created_languages
        missing_languages.map { |detected_language| create_language(detected_language) }
      end

      def missing_languages
        detected_languages.reject do |detected_language|
          existing_language_names.include?(detected_language.name)
        end
      end

      def existing_language_names
        @existing_language_names ||= existing_languages.map(&:name)
      end

      # rubocop:disable CodeReuse/ActiveRecord -- This resolver owns ProgrammingLanguage lookup and creation.
      def existing_languages
        @existing_languages ||= ProgrammingLanguage.where(name: detected_languages.map(&:name)).to_a
      end

      def create_language(detected_language)
        attrs = {
          color: detected_language.color,
          language_id: detected_language.language_id
        }.compact

        ProgrammingLanguage.transaction do
          ProgrammingLanguage.where(name: detected_language.name).first_or_create(attrs)
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
  # rubocop:enable Gitlab/NamespacedClass
end
