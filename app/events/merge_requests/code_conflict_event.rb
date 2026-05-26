# frozen_string_literal: true

module MergeRequests
  class CodeConflictEvent < Gitlab::EventStore::CloudEvent
    event_category :merge_requests
    event_type :code_conflict

    class << self
      def build(merge_request:)
        return if merge_request.author.nil?

        build_cloud_event(
          source: "projects/#{merge_request.project.id}",
          subject: "merge_requests/#{merge_request.id}",
          current_user: merge_request.author,
          organization: merge_request.project.organization,
          event_data: generate_event_data(merge_request)
        )
      end

      private

      def generate_event_data(merge_request)
        {
          merge_request_id: merge_request.id,
          merge_request_iid: merge_request.iid,
          project_id: merge_request.project_id
        }
      end
    end

    def data_schema
      {
        'type' => 'object',
        'properties' => {
          'merge_request_iid' => { 'type' => 'integer' },
          'merge_request_id' => { 'type' => 'integer' },
          'project_id' => { 'type' => 'integer' }
        },
        'required' => %w[merge_request_iid merge_request_id project_id]
      }
    end
  end
end
