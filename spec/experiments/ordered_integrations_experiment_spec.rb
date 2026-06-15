# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OrderedIntegrationsExperiment, :experiment, feature_category: :integrations do
  it 'resolves the ordered_integrations experiment name to this class' do
    expect(described_class).to eq(Gitlab::Experiment.constantize(:ordered_integrations))
  end

  context 'with the control variant' do
    before do
      stub_experiments(ordered_integrations: :control)
    end

    it 'runs the registered experiment without raising' do
      expect { experiment(:ordered_integrations).run }.not_to raise_error
    end
  end

  context 'with the candidate variant' do
    before do
      stub_experiments(ordered_integrations: :candidate)
    end

    it 'runs the registered experiment without raising' do
      expect { experiment(:ordered_integrations).run }.not_to raise_error
    end
  end
end
