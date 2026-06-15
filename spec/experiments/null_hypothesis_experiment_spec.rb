# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NullHypothesisExperiment, :experiment, feature_category: :acquisition do
  it 'resolves the null_hypothesis experiment name to this class' do
    expect(described_class).to eq(Gitlab::Experiment.constantize(:null_hypothesis))
  end

  context 'with the control variant' do
    before do
      stub_experiments(null_hypothesis: :control)
    end

    it 'runs the registered experiment without raising' do
      expect { experiment(:null_hypothesis).run }.not_to raise_error
    end
  end

  context 'with the candidate variant' do
    before do
      stub_experiments(null_hypothesis: :candidate)
    end

    it 'runs the registered experiment without raising' do
      expect { experiment(:null_hypothesis).run }.not_to raise_error
    end
  end
end
