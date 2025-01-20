# frozen_string_literal: true

module Resolvers
  module Ci
    class ProjectPipelineAnalyticsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Ci::AnalyticsType, null: true

      authorizes_object!
      authorize :read_ci_cd_analytics
      extras [:lookahead]

      alias_method :project, :object

      argument :source, Types::PipelineCiSourcesEnum,
        required: false,
        description: 'Source of the pipeline.',
        experiment: { milestone: '17.5' }

      argument :ref, GraphQL::Types::String,
        required: false,
        description: 'Branch that triggered the pipeline.',
        experiment: { milestone: '17.5' }

      argument :from_time, Types::TimeType,
        required: false,
        description: 'Start of the requested time frame. Defaults to the pipelines started in the past week.',
        experiment: { milestone: '17.5' }

      argument :to_time, Types::TimeType,
        required: false,
        description: 'End of the requested time frame. Defaults to pipelines started before the current date.',
        experiment: { milestone: '17.5' }

      def resolve(lookahead:, source: nil, ref: nil, from_time: nil, to_time: nil)
        result = legacy_fields(lookahead)

        if any_field_selected?(lookahead, :aggregate)
          aggregate_lookahead = lookahead&.selection(:aggregate)
          response =
            ::Ci::CollectPipelineAnalyticsService.new(
              current_user: context[:current_user], project: project,
              source: source, ref: ref,
              from_time: from_time, to_time: to_time,
              status_groups: selected_status_groups(aggregate_lookahead),
              duration_percentiles: selected_duration_percentiles(aggregate_lookahead)
            ).execute

          raise_resource_not_available_error! response.message if response.error?

          result[:aggregate] = response.payload[:aggregate]
        end

        result
      end

      private

      def legacy_fields(lookahead)
        # NOTE: The fields below will eventually be deprecated once we move to using the new `aggregate`
        # and `graph` fields (see https://gitlab.com/gitlab-org/gitlab/-/issues/444468/#proposed-api-layout)
        weekly_stats = Gitlab::Ci::Charts::WeekChart.new(project, selected_period_statuses(lookahead, :week))
        monthly_stats = Gitlab::Ci::Charts::MonthChart.new(project, selected_period_statuses(lookahead, :month))
        yearly_stats = Gitlab::Ci::Charts::YearChart.new(project, selected_period_statuses(lookahead, :year))

        result = {}
        if any_field_selected?(lookahead, :week_pipelines_labels, :week_pipelines_totals, :week_pipelines_successful)
          result.merge!(
            week_pipelines_labels: weekly_stats.labels,
            week_pipelines_totals: weekly_stats.totals(status: :all),
            week_pipelines_successful: weekly_stats.totals(status: :success))
        end

        if any_field_selected?(lookahead, :month_pipelines_labels, :month_pipelines_totals, :month_pipelines_successful)
          result.merge!(
            month_pipelines_labels: monthly_stats.labels,
            month_pipelines_totals: monthly_stats.totals(status: :all),
            month_pipelines_successful: monthly_stats.totals(status: :success))
        end

        if any_field_selected?(lookahead, :year_pipelines_labels, :year_pipelines_totals, :year_pipelines_successful)
          result.merge!(
            year_pipelines_labels: yearly_stats.labels,
            year_pipelines_totals: yearly_stats.totals(status: :all),
            year_pipelines_successful: yearly_stats.totals(status: :success))
        end

        if any_field_selected?(lookahead, :pipeline_times_labels, :pipeline_times_values)
          pipeline_times = Gitlab::Ci::Charts::PipelineTime.new(project, [])
          result.merge!(
            pipeline_times_labels: pipeline_times.labels,
            pipeline_times_values: pipeline_times.pipeline_times)
        end

        result
      end

      def any_field_selected?(lookahead, *fields)
        fields.any? { |field| lookahead&.selects?(field) }
      end

      def selected_status_groups(aggregate_lookahead)
        return [] unless aggregate_lookahead&.selects?(:count)

        selection = []
        selection << :any if aggregate_lookahead.selects?(:count, arguments: { status: :any })
        selection + ::Ci::CollectPipelineAnalyticsService::STATUS_GROUPS.filter do |status|
          aggregate_lookahead.selects?(:count, arguments: { status: status })
        end
      end

      def selected_period_statuses(lookahead, period)
        return [] unless lookahead

        selected = ::Ci::CollectPipelineAnalyticsService::STATUS_GROUPS.filter do |status|
          lookahead.selection(:"#{period}_pipelines").selects?(:totals, arguments: { status: status })
        end
        selected << :success if lookahead.selects?(:"#{period}_pipelines_successful")

        selected.sort.uniq
      end

      def selected_duration_percentiles(aggregate_lookahead)
        return [] unless aggregate_lookahead

        ::Ci::CollectPipelineAnalyticsService::ALLOWED_PERCENTILES.filter do |percentile|
          aggregate_lookahead.selection(:duration_statistics).selects?("p#{percentile}")
        end
      end
    end
  end
end
