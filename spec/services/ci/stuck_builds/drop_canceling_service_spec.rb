# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StuckBuilds::DropCancelingService, feature_category: :continuous_integration do
  let_it_be(:runner) { create :ci_runner }
  let!(:job) { create(:ci_build, runner: runner, created_at: created_at, updated_at: updated_at, status: status) }
  let(:outdated_time) { described_class::TIMEOUT.ago - 15.minutes }
  let(:fresh_time) { described_class::TIMEOUT.ago + 15.minutes }

  subject(:service) { described_class.new }

  around do |example|
    freeze_time { example.run }
  end

  shared_examples 'canceling builds' do
    context 'when job is canceling' do
      let(:status) { 'canceling' }

      context 'when job is outdated' do
        let(:created_at) { outdated_time }
        let(:updated_at) { outdated_time }

        it_behaves_like 'job is canceled'
        it_behaves_like 'when invalid dooms the job bypassing validations'
      end

      context 'when job is fresh' do
        let(:created_at) { fresh_time }
        let(:updated_at) { fresh_time }

        it_behaves_like 'job is unchanged'
      end

      context 'when job freshly updated' do
        let(:created_at) { outdated_time }
        let(:updated_at) { fresh_time }

        it_behaves_like 'job is unchanged'
      end
    end
  end

  include_examples 'canceling builds'

  context 'when the ci_lower_stuck_build_timeouts flag is disabled' do
    let(:status) { 'canceling' }

    before do
      stub_feature_flags(ci_lower_stuck_build_timeouts: false)
    end

    context 'when idle past the new timeout but within the old one' do
      let(:created_at) { 45.minutes.ago }
      let(:updated_at) { 45.minutes.ago }

      it_behaves_like 'job is unchanged'
    end

    context 'when idle beyond the old timeout' do
      let(:created_at) { (described_class::OLD_TIMEOUT + 30.minutes).ago }
      let(:updated_at) { (described_class::OLD_TIMEOUT + 30.minutes).ago }

      it_behaves_like 'job is canceled'
    end
  end

  %w[success skipped failed canceled scheduled pending].each do |status|
    context "when job is #{status}" do
      let(:status) { status }
      let(:updated_at) { outdated_time }

      context 'when created_at is the same as updated_at' do
        let(:created_at) { outdated_time }

        it_behaves_like 'job is unchanged'
      end
    end
  end
end
