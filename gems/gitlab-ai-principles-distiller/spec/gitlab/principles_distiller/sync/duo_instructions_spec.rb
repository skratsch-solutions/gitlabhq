# frozen_string_literal: true

require 'spec_helper'
require 'yaml'
require_relative '../../../../lib/gitlab/principles_distiller/sync/duo_instructions'

RSpec.describe Gitlab::PrinciplesDistiller::Sync::DuoInstructions do
  # A minimal but representative file: a hand-authored group, one generated
  # region, and a trailing hand-authored group, so tests can prove the
  # generator only touches the fenced region.
  let(:fixture) do
    <<~YAML
      instructions:
        - name: Hand authored
          fileFilters:
            - "**/*.rb"
          instructions: |
            1. Keep this group untouched.

        # >>> generated: documentation — gitlab-ai-principles-distiller (from .ai/principles/manifest.yml; do not edit)
        # distilled_at_sha: oldsha111
        # source_checksum: oldsum11
        - name: Documentation
          fileFilters:
            - "doc/**/*.md"
          instructions: |
            Stale body to be replaced.
        # <<< end generated: documentation

        - name: Trailing group
          fileFilters:
            - "**/*.js"
          instructions: |
            1. Also untouched.
    YAML
  end

  let(:distilled_body) do
    <<~BODY.rstrip
      ### Voice and Tone

      - Write in US English.
      - Use active voice.

      ### Capitalization

      - Use sentence case for topic titles.
    BODY
  end

  let(:fences) do
    {
      'documentation' => {
        name: 'Documentation',
        file_filters: ['doc/**/*.md'],
        distilled_body: distilled_body,
        distilled_at_sha: 'newsha222',
        source_checksum: 'newsum22',
        references: [
          'doc/development/documentation/styleguide/_index.md',
          'doc/development/documentation/styleguide/word_list.md'
        ]
      }
    }
  end

  describe '.fenced_principles' do
    it 'returns the principle keys with generated regions in document order' do
      extra = <<~EXTRA.gsub(/^/, '  ')
        # >>> generated: documentation-api — gitlab-ai-principles-distiller (from .ai/principles/manifest.yml; do not edit)
        # distilled_at_sha: x
        # source_checksum: y
        - name: API documentation
          fileFilters:
            - "doc/api/**/*.md"
          instructions: |
            body
        # <<< end generated: documentation-api
      EXTRA

      expect(described_class.fenced_principles(fixture + extra)).to eq(%w[documentation documentation-api])
    end

    it 'returns an empty array when no regions exist' do
      expect(described_class.fenced_principles('instructions: []')).to eq([])
    end
  end

  describe '.regenerate' do
    subject(:regenerated) { described_class.regenerate(fixture, fences: fences) }

    it 'refreshes the distilled_at_sha and source_checksum directives' do
      expect(regenerated).to include('  # distilled_at_sha: newsha222')
      expect(regenerated).to include('  # source_checksum: newsum22')
      expect(regenerated).not_to include('oldsha111')
      expect(regenerated).not_to include('oldsum11')
    end

    it 'preserves the hand-authored name and fileFilters' do
      expect(regenerated).to include("  - name: Documentation\n    fileFilters:\n      - \"doc/**/*.md\"")
    end

    it 'replaces the body with the distilled checklist sections' do
      expect(regenerated).to include('      ### Voice and Tone')
      expect(regenerated).to include('      - Write in US English.')
      expect(regenerated).to include('      ### Capitalization')
      expect(regenerated).not_to include('Stale body to be replaced.')
    end

    it 'starts the body directly with the distilled checklist, with no intro preamble' do
      expect(regenerated).to include("    instructions: |\n      ### Voice and Tone")
      expect(regenerated).not_to include('Sourced from the distilled')
      expect(regenerated).not_to include('Treat as guidance')
    end

    it 'appends a Reference line (repo-relative path) for every injected source' do
      expect(regenerated).to include(
        '      - Reference: doc/development/documentation/styleguide/_index.md'
      )
      expect(regenerated).to include(
        '      - Reference: doc/development/documentation/styleguide/word_list.md'
      )
    end

    it 'leaves hand-authored groups outside the region untouched' do
      expect(regenerated).to include('1. Keep this group untouched.')
      expect(regenerated).to include('1. Also untouched.')
      expect(regenerated).to include('  - name: Trailing group')
    end

    it 'produces valid YAML' do
      expect { YAML.safe_load(regenerated) }.not_to raise_error
    end

    it 'is idempotent' do
      once = described_class.regenerate(fixture, fences: fences)
      twice = described_class.regenerate(once, fences: fences)
      expect(twice).to eq(once)
    end

    it 'preserves a "# fileFilters:" override directive when present' do
      with_override = fixture.sub(
        "    fileFilters:\n      - \"doc/**/*.md\"",
        "    fileFilters:\n      - \"doc/api/**/*.md\""
      )
      result = described_class.regenerate(with_override, fences: fences)
      expect(result).to include("      - \"doc/api/**/*.md\"")
      expect(result).not_to include("      - \"doc/**/*.md\"")
    end

    context 'when a fenced principle is absent from the fences data' do
      it 'leaves that region untouched' do
        result = described_class.regenerate(fixture, fences: {})
        expect(result).to eq(fixture)
      end
    end
  end

  describe '.check' do
    it 'returns the principle when the recorded directives are stale' do
      expect(described_class.check(fixture, fences: fences)).to eq(['documentation'])
    end

    it 'returns an empty array when the recorded directives match' do
      current = fences.transform_values do |data|
        data.merge(distilled_at_sha: 'oldsha111', source_checksum: 'oldsum11')
      end
      expect(described_class.check(fixture, fences: current)).to eq([])
    end

    it 'ignores fenced principles absent from the fences data' do
      expect(described_class.check(fixture, fences: {})).to eq([])
    end

    it 'detects staleness when only the checksum differs' do
      partial = fences.transform_values do |data|
        data.merge(distilled_at_sha: 'oldsha111', source_checksum: 'different')
      end
      expect(described_class.check(fixture, fences: partial)).to eq(['documentation'])
    end
  end
end
