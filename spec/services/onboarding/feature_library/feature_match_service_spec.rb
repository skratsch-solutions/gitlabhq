# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::FeatureLibrary::FeatureMatchService, feature_category: :onboarding do
  before do
    allow(Onboarding::FeatureLibrary::TerminologyMap).to receive(:all).and_return(
      [
        { 'term' => 'pr',               'feature_key' => 'project_merge_request_list', 'panels' => ['project'] },
        { 'term' => 'pr',               'feature_key' => 'group_merge_request_list',   'panels' => ['group'] },
        { 'term' => 'prs',              'feature_key' => 'project_merge_request_list', 'panels' => ['project'] },
        { 'term' => 'prs',              'feature_key' => 'group_merge_request_list',   'panels' => ['group'] },
        { 'term' => 'pull request',     'feature_key' => 'project_merge_request_list', 'panels' => ['project'] },
        { 'term' => 'pull request',     'feature_key' => 'group_merge_request_list',   'panels' => ['group'] },
        { 'term' => 'issue',            'feature_key' => 'project_issue_list',         'panels' => ['project'] },
        { 'term' => 'issue',            'feature_key' => 'group_issue_list',           'panels' => ['group'] },
        { 'term' => 'ticket',           'feature_key' => 'project_issue_list',         'panels' => ['project'] },
        { 'term' => 'ticket',           'feature_key' => 'group_issue_list',           'panels' => ['group'] },
        { 'term' => 'sprint',           'feature_key' => 'boards',
          'panels' => %w[project group] },
        { 'term' => 'pipeline',         'feature_key' => 'pipelines',                 'panels' => ['project'] },
        { 'term' => 'analytics',        'feature_key' => 'cycle_analytics',           'panels' => ['project'] },
        { 'term' => 'pipeline analytics', 'feature_key' => 'ci_cd_analytics',         'panels' => ['project'] },
        { 'term' => 'members', 'feature_key' => 'members', 'panels' => %w[project group] }
      ].freeze
    )
  end

  describe '#execute' do
    subject(:result) { described_class.new(query: query, panel: panel).execute }

    context 'with a project panel' do
      let(:panel) { 'project' }

      context 'when the query is an exact synonym' do
        let(:query) { 'pr' }

        it 'returns multiple matched ids with the exact match first', :aggregate_failures do
          expect(result.length).to be > 1
          expect(result.first).to eq('project_merge_request_list')
        end
      end

      context 'when the query is a prefix of a synonym ("pull" starts "pull request")' do
        let(:query) { 'pull' }

        it 'returns the matching item_id first' do
          expect(result.first).to eq('project_merge_request_list')
        end
      end

      context 'when the query is a substring of a synonym ("analytics" inside "pipeline analytics")' do
        let(:query) { 'analytics' }

        it 'returns all matched ids including the substring hit' do
          expect(result).to include('ci_cd_analytics')
        end

        it 'ranks the exact match before the substring hit', :aggregate_failures do
          expect(result).to include('cycle_analytics', 'ci_cd_analytics')
          expect(result.index('cycle_analytics')).to be < result.index('ci_cd_analytics')
        end
      end

      context 'when multiple entries map to the same feature_key' do
        let(:query) { 'issue' }

        it 'returns the feature_key only once' do
          expect(result.count('project_issue_list')).to eq(1)
        end
      end

      context 'when the query needs normalization (uppercase, whitespace)' do
        let(:query) { '  PR  ' }

        it 'normalizes and returns the exact-matched id first' do
          expect(result.first).to eq('project_merge_request_list')
        end
      end

      context 'when the query is shorter than MIN_QUERY_LENGTH' do
        let(:query) { 'p' }

        it 'returns an empty array' do
          expect(result).to eq([])
        end
      end

      context 'when the query does not match any term' do
        let(:query) { 'completelyrandom' }

        it 'returns an empty array' do
          expect(result).to eq([])
        end
      end

      context 'when the query is blank' do
        let(:query) { '' }

        it 'returns an empty array' do
          expect(result).to eq([])
        end
      end

      context 'when a short query substring-matches multiple features ("pr" inside "sprint")' do
        let(:query) { 'pr' }

        it 'ranks the exact match first and includes the substring-collision match', :aggregate_failures do
          expect(result.first).to eq('project_merge_request_list')
          expect(result).to include('boards')
        end
      end

      context 'when a term is valid in both panels (e.g. "members")' do
        let(:query) { 'members' }

        it 'returns the feature_key for the given panel' do
          expect(result).to include('members')
        end
      end
    end

    context 'with a group panel' do
      let(:panel) { 'group' }

      context 'when the query resolves to issues' do
        let(:query) { 'ticket' }

        it 'returns the group-panel id' do
          expect(result).to eq(['group_issue_list'])
        end
      end

      context 'when the query resolves to a project-only feature' do
        let(:query) { 'pipeline' }

        it 'returns an empty array (no group entry for pipelines)' do
          expect(result).to eq([])
        end
      end

      context 'when a term is valid in both panels (e.g. "members")' do
        let(:query) { 'members' }

        it 'returns the shared feature_key for the given panel' do
          expect(result).to include('members')
        end
      end

      context 'when a substring match would only resolve project-only features' do
        let(:query) { 'analytics' }

        it 'returns an empty array' do
          expect(result).to eq([])
        end
      end
    end

    context 'with an invalid panel' do
      let(:query) { 'pr' }
      let(:panel) { 'invalid_panel' }

      it 'returns an empty array' do
        expect(result).to eq([])
      end
    end
  end
end
