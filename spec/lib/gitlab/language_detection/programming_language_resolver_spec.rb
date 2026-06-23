# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LanguageDetection::ProgrammingLanguageResolver, feature_category: :source_code_management do
  subject(:resolved_languages) { described_class.new(detected_languages).execute }

  describe '#execute' do
    context 'when all detected languages already exist by name' do
      let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
      let_it_be(:javascript) { create(:programming_language, name: 'JavaScript') }

      let(:detected_languages) do
        [
          detected_language(name: 'Ruby', color: '#701516', language_id: 326),
          detected_language(name: 'JavaScript', color: '#f1e05a', language_id: 158)
        ]
      end

      it 'returns the existing languages without creating records', :aggregate_failures do
        languages = nil

        expect { languages = resolved_languages.to_a }.not_to change { ProgrammingLanguage.count }

        expect(languages).to contain_exactly(ruby, javascript)
      end
    end

    context 'when some detected languages are missing' do
      let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }

      let(:detected_languages) do
        [
          detected_language(name: 'Ruby', color: '#701516', language_id: 326),
          detected_language(name: 'NewLang', color: '#abcdef', language_id: 12345)
        ]
      end

      it 'creates the missing languages and returns existing and created languages', :aggregate_failures do
        expect { resolved_languages }.to change { ProgrammingLanguage.count }.by(1)

        new_language = ProgrammingLanguage.find_by!(name: 'NewLang')
        expect(new_language.color).to eq('#abcdef')
        expect(new_language.language_id).to eq(12345)
        expect(resolved_languages).to contain_exactly(ruby, new_language)
      end
    end

    context 'when a detected language has a nil language_id' do
      let(:detected_languages) do
        [detected_language(name: 'NewLang', color: '#abcdef', language_id: nil)]
      end

      it 'creates the language with a nil language_id', :aggregate_failures do
        expect { resolved_languages }.to change { ProgrammingLanguage.count }.by(1)

        new_language = ProgrammingLanguage.find_by!(name: 'NewLang')
        expect(new_language.language_id).to be_nil
        expect(resolved_languages).to contain_exactly(new_language)
      end
    end

    context 'when an existing language has a stale language_id' do
      let_it_be(:ruby) { create(:programming_language, name: 'Ruby', language_id: nil) }

      let(:detected_languages) do
        [detected_language(name: 'Ruby', color: '#701516', language_id: 326)]
      end

      it 'does not update the existing language by language_id', :aggregate_failures do
        languages = nil

        expect { languages = resolved_languages.to_a }.not_to change { ProgrammingLanguage.count }

        expect(ruby.reload.language_id).to be_nil
        expect(languages).to contain_exactly(ruby)
      end
    end

    context 'when detected_languages is empty' do
      let(:detected_languages) { [] }

      it 'returns an empty result without creating records', :aggregate_failures do
        languages = nil

        expect { languages = resolved_languages }.not_to change { ProgrammingLanguage.count }

        expect(languages).to be_empty
      end
    end
  end

  def detected_language(name:, color:, language_id:)
    Gitlab::LanguageDetection::DetectedLanguage.new(
      name: name,
      share: 100.0,
      color: color,
      language_id: language_id
    )
  end
end
