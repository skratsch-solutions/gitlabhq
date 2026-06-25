# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MarkdownCache, feature_category: :markdown do
  let(:rollout_flag) { :"markdown_cache_stochastic_rollout_#{described_class::CACHE_COMMONMARK_VERSION}" }

  describe '.latest_cached_markdown_version' do
    context 'in steady state' do
      before do
        stub_const("#{described_class}::CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED", nil)
      end

      it 'returns the current shifted version regardless of rollout flag', :aggregate_failures do
        stub_application_setting(local_markdown_version: 2)

        stub_feature_flags(rollout_flag => false)

        expect(described_class.latest_cached_markdown_version(local_version: nil))
          .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 2

        stub_feature_flags(rollout_flag => true)

        expect(described_class.latest_cached_markdown_version(local_version: nil))
          .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 2
      end

      it 'uses the passed in local_version' do
        stub_application_setting(local_markdown_version: 2)

        expect(described_class.latest_cached_markdown_version(local_version: 5))
          .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 5
      end
    end

    context 'when a rollout is in progress' do
      let(:previous_shifted) { (described_class::CACHE_COMMONMARK_VERSION - 1) << 16 }

      before do
        stub_const("#{described_class}::CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED", previous_shifted)
        stub_feature_flags(rollout_flag => false)
      end

      context 'when the stochastic rollout flag is disabled' do
        it 'returns the previous shifted version OR-ed with the application local version' do
          stub_application_setting(local_markdown_version: 2)

          expect(described_class.latest_cached_markdown_version(local_version: nil))
            .to eq previous_shifted | 2
        end

        it 'uses the passed in local_version' do
          stub_application_setting(local_markdown_version: 2)

          expect(described_class.latest_cached_markdown_version(local_version: 5))
            .to eq previous_shifted | 5
        end
      end

      context 'when the stochastic rollout flag is fully enabled' do
        before do
          stub_feature_flags(rollout_flag => true)
        end

        it 'returns the current shifted version OR-ed with the application local version' do
          stub_application_setting(local_markdown_version: 2)

          expect(described_class.latest_cached_markdown_version(local_version: nil))
            .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 2
        end

        it 'uses the passed in local_version' do
          stub_application_setting(local_markdown_version: 2)

          expect(described_class.latest_cached_markdown_version(local_version: 5))
            .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 5
        end
      end
    end
  end

  describe '.cached_markdown_version_for_write' do
    context 'in steady state' do
      before do
        stub_const("#{described_class}::CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED", nil)
      end

      it 'returns the current shifted version OR-ed with the application local version' do
        stub_application_setting(local_markdown_version: 2)

        expect(described_class.cached_markdown_version_for_write(local_version: nil))
          .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 2
      end

      it 'uses the passed in local_version' do
        stub_application_setting(local_markdown_version: 2)

        expect(described_class.cached_markdown_version_for_write(local_version: 5))
          .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 5
      end
    end

    context 'when a rollout is in progress' do
      let(:previous_shifted) { (described_class::CACHE_COMMONMARK_VERSION - 1) << 16 }

      before do
        stub_const("#{described_class}::CACHE_COMMONMARK_VERSION_PREVIOUS_SHIFTED", previous_shifted)
      end

      it 'returns the current shifted version regardless of rollout flag', :aggregate_failures do
        stub_application_setting(local_markdown_version: 2)
        stub_feature_flags(rollout_flag => false)

        expect(described_class.cached_markdown_version_for_write(local_version: nil))
          .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 2

        stub_feature_flags(rollout_flag => true)

        expect(described_class.cached_markdown_version_for_write(local_version: nil))
          .to eq described_class::CACHE_COMMONMARK_VERSION_SHIFTED | 2
      end
    end
  end
end
