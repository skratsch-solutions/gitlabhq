# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/events/merge_requests/assigned_reviewers_event'
require_relative '../../support/shared_examples/events/cloud_event_with_schema_shared_examples'

RSpec.describe MergeRequests::CodeConflictEvent, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }

  describe '.build' do
    it 'returns a valid CodeConflictEvent' do
      event = described_class.build(merge_request: merge_request)
      expect(event.event_category).to eq(:merge_requests)
      expect(event.event_type).to eq(:code_conflict)
    end
  end

  it_behaves_like 'a cloud event with schema',
    valid_data: {
      merge_request_id: 1,
      merge_request_iid: 10,
      project_id: 100
    },
    missing_required: %i[merge_request_id merge_request_iid project_id],
    invalid_types: {
      merge_request_id: 'not_an_integer',
      merge_request_iid: 'not_an_integer',
      project_id: 'not_an_integer'
    }
end
