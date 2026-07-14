# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../lib/gitlab/ci/trace_context'

RSpec.describe Gitlab::Observability::PipelineToLogs, feature_category: :observability do
  let(:integration) do
    Struct.new(:otel_endpoint_url, :otel_headers, :service_name, :environment).new(
      'https://example.com/otel',
      {},
      'gitlab-ci',
      'production'
    )
  end

  let(:pipeline_data) do
    {
      object_attributes: {
        id: 123,
        iid: 456,
        name: 'test-pipeline',
        ref: 'main',
        sha: 'abc123',
        source: 'push',
        status: 'success',
        detailed_status: 'passed',
        created_at: Time.zone.parse('2023-01-01T10:00:00Z'),
        finished_at: Time.zone.parse('2023-01-01T10:05:00Z'),
        duration: 300000,
        queued_duration: 30000,
        protected_ref: true,
        url: 'https://gitlab.com/project/-/pipelines/123',
        stages: %w[test build deploy]
      },
      project: {
        id: 789,
        name: 'test-project'
      },
      builds: [
        {
          id: 1,
          name: 'test-job',
          stage: 'test',
          status: 'success',
          started_at: Time.zone.parse('2023-01-01T10:01:00Z'),
          finished_at: Time.zone.parse('2023-01-01T10:03:00Z'),
          duration: 120000,
          queued_duration: 5000,
          manual: false,
          allow_failure: false,
          runner: {
            id: 1,
            description: 'test-runner',
            active: true,
            url: 'https://gitlab.com/runners/1',
            tags: %w[docker linux],
            runner_type: 'instance_type'
          },
          artifacts_file: {
            filename: 'test-results.xml',
            size: 1024
          }
        },
        {
          id: 2,
          name: 'failed-job',
          stage: 'build',
          status: 'failed',
          started_at: Time.zone.parse('2023-01-01T10:03:00Z'),
          finished_at: Time.zone.parse('2023-01-01T10:04:00Z'),
          duration: 60000,
          queued_duration: 2000,
          manual: true,
          allow_failure: true,
          failure_reason: 'script_failure'
        }
      ]
    }
  end

  let(:converter) { described_class.new(integration, pipeline_data) }

  describe '#convert' do
    it 'returns valid OTEL logs format' do
      result = converter.convert

      aggregate_failures do
        expect(result).to have_key(:resourceLogs)
        expect(result[:resourceLogs]).to be_an(Array)
        expect(result[:resourceLogs].length).to eq(1)
      end
    end

    context 'with trace context correlation' do
      let(:root_pipeline_id) { 123 }
      let(:expected_trace_id) { Gitlab::Ci::TraceContext.trace_id_for(root_pipeline_id) }

      it 'includes traceId on pipeline log record' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        pipeline_log = log_records.find do |log|
          log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
        end

        expect(pipeline_log[:traceId]).to eq(expected_trace_id)
      end

      it 'includes spanId on pipeline log record matching TraceContext derivation' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        pipeline_log = log_records.find do |log|
          log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
        end

        expected_span_id = Gitlab::Ci::TraceContext.span_id_for_pipeline(root_pipeline_id, 123)
        expect(pipeline_log[:spanId]).to eq(expected_span_id)
      end

      it 'includes traceId on job log records' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        job_logs = log_records.select do |log|
          log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'job' }
        end

        aggregate_failures do
          job_logs.each do |job_log|
            expect(job_log[:traceId]).to eq(expected_trace_id)
          end
        end
      end

      it 'includes distinct spanId per job log record' do
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

        job_logs = log_records.select do |log|
          log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'job' }
        end

        span_ids = job_logs.map { |log| log[:spanId] }

        aggregate_failures do
          expect(span_ids.uniq.size).to eq(2)
          expect(span_ids.first).to eq(Gitlab::Ci::TraceContext.span_id_for_job(root_pipeline_id, 1, :export))
          expect(span_ids.last).to eq(Gitlab::Ci::TraceContext.span_id_for_job(root_pipeline_id, 2, :export))
        end
      end

      context 'with root_pipeline_id in pipeline data' do
        let(:root_pipeline_id) { 999 }

        before do
          pipeline_data[:object_attributes][:root_pipeline_id] = root_pipeline_id
        end

        it 'uses root_pipeline_id for trace correlation' do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

          pipeline_log = log_records.find do |log|
            log[:attributes].any? { |attr| attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline' }
          end

          expect(pipeline_log[:traceId]).to eq(Gitlab::Ci::TraceContext.trace_id_for(999))
        end
      end

      it 'produces trace IDs matching PipelineToTraces for the same pipeline', :aggregate_failures do
        logs_result = converter.convert
        traces_converter = Gitlab::Observability::PipelineToTraces.new(integration, pipeline_data)
        traces_result = traces_converter.convert

        log_trace_id = logs_result[:resourceLogs].first[:scopeLogs].first[:logRecords].first[:traceId]
        span_trace_id = traces_result[:resourceSpans].first[:scopeSpans].first[:spans].first[:traceId]

        expect(log_trace_id).to eq(span_trace_id)
      end
    end

    it 'includes resource attributes' do
      result = converter.convert
      resource = result[:resourceLogs].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'gitlab-ci' } },
        { key: 'gitlab.project.id', value: { intValue: 789 } },
        { key: 'gitlab.pipeline.id', value: { intValue: 123 } }
      )
    end

    it 'includes pipeline log record' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      aggregate_failures do
        expect(pipeline_log).to be_present
        expect(pipeline_log[:body][:stringValue]).to include('Pipeline success: test-pipeline')
        expect(pipeline_log[:severityText]).to eq('INFO')
      end
    end

    it 'includes job log records' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      job_logs = log_records.select do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'job'
        end
      end
      expect(job_logs.length).to eq(2)

      success_job_log = job_logs.find { |log| log[:body][:stringValue].include?('test-job') }
      aggregate_failures do
        expect(success_job_log).to be_present
        expect(success_job_log[:severityText]).to eq('INFO')
      end

      failed_job_log = job_logs.find { |log| log[:body][:stringValue].include?('failed-job') }
      aggregate_failures do
        expect(failed_job_log).to be_present
        expect(failed_job_log[:severityText]).to eq('ERROR')
      end
    end

    it 'sets correct severity levels' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      aggregate_failures do
        expect(pipeline_log[:severityNumber]).to eq(9) # INFO
        expect(pipeline_log[:severityText]).to eq('INFO')
      end

      failed_job_log = log_records.find { |log| log[:body][:stringValue].include?('failed-job') }
      aggregate_failures do
        expect(failed_job_log[:severityNumber]).to eq(17) # ERROR
        expect(failed_job_log[:severityText]).to eq('ERROR')
      end
    end

    it 'includes pipeline attributes' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      attributes = pipeline_log[:attributes]

      expect(attributes).to include(
        { key: 'pipeline.id', value: { intValue: 123 } },
        { key: 'pipeline.name', value: { stringValue: 'test-pipeline' } },
        { key: 'pipeline.status', value: { stringValue: 'success' } },
        { key: 'pipeline.duration', value: { intValue: 300000 } }
      )
    end

    it 'includes job attributes' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      job_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }
      attributes = job_log[:attributes]

      expect(attributes).to include(
        { key: 'job.id', value: { intValue: 1 } },
        { key: 'job.name', value: { stringValue: 'test-job' } },
        { key: 'job.stage', value: { stringValue: 'test' } },
        { key: 'job.status', value: { stringValue: 'success' } },
        { key: 'job.runner.id', value: { intValue: 1 } },
        { key: 'job.artifacts.filename', value: { stringValue: 'test-results.xml' } }
      )
    end

    it 'handles empty pipeline data' do
      empty_data = {}
      converter = described_class.new(integration, empty_data)

      result = converter.convert
      expect(result[:resourceLogs]).to be_empty
    end

    it 'handles missing timestamps gracefully' do
      pipeline_data[:object_attributes].delete(:finished_at)
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      expect(pipeline_log[:timeUnixNano]).to be > 0
    end

    it 'handles invalid timestamps gracefully' do
      pipeline_data[:object_attributes][:finished_at] = 'not-a-timestamp'
      pipeline_data[:object_attributes][:created_at] = 'also-invalid'
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      expect(pipeline_log[:timeUnixNano]).to eq(0)
    end

    it 'includes failure reason for failed jobs' do
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      failed_job_log = log_records.find { |log| log[:body][:stringValue].include?('failed-job') }
      attributes = failed_job_log[:attributes]

      expect(attributes).to include(
        { key: 'job.failure_reason', value: { stringValue: 'script_failure' } }
      )
    end

    it 'uses custom service name from integration' do
      integration.service_name = 'custom-service'
      result = converter.convert
      resource = result[:resourceLogs].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'service.name', value: { stringValue: 'custom-service' } }
      )
    end

    it 'uses custom environment from integration' do
      integration.environment = 'staging'
      result = converter.convert
      resource = result[:resourceLogs].first[:resource]

      expect(resource[:attributes]).to include(
        { key: 'deployment.environment', value: { stringValue: 'staging' } }
      )
    end

    it 'handles different pipeline statuses' do
      pipeline_data[:object_attributes][:status] = 'canceled'
      result = converter.convert
      log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]

      pipeline_log = log_records.find do |log|
        log[:attributes].any? do |attr|
          attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
        end
      end
      expect(pipeline_log[:severityText]).to eq('WARN')
    end

    context 'with OTel Semantic Convention attributes' do
      describe 'resource-level semconv attributes' do
        it 'includes cicd.pipeline.run.id as string' do
          result = converter.convert
          resource = result[:resourceLogs].first[:resource]

          expect(resource[:attributes]).to include(
            { key: 'cicd.pipeline.run.id', value: { stringValue: '123' } }
          )
        end

        it 'includes vcs.ref.head.name' do
          result = converter.convert
          resource = result[:resourceLogs].first[:resource]

          expect(resource[:attributes]).to include(
            { key: 'vcs.ref.head.name', value: { stringValue: 'main' } }
          )
        end
      end

      describe 'pipeline log semconv attributes' do
        let(:pipeline_log) do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          log_records.find do |log|
            log[:attributes].any? do |attr|
              attr[:key] == 'log.source' && attr[:value][:stringValue] == 'pipeline'
            end
          end
        end

        it 'includes cicd.pipeline.name' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'cicd.pipeline.name', value: { stringValue: 'test-pipeline' } }
          )
        end

        it 'omits cicd.pipeline.name when pipeline name is blank' do
          pipeline_data[:object_attributes][:name] = nil
          name_attrs = pipeline_log[:attributes].select { |attr| attr[:key] == 'cicd.pipeline.name' }
          expect(name_attrs).to be_empty
        end

        it 'omits cicd.pipeline.run.url.full when url is blank' do
          pipeline_data[:object_attributes][:url] = nil
          url_attrs = pipeline_log[:attributes].select { |attr| attr[:key] == 'cicd.pipeline.run.url.full' }
          expect(url_attrs).to be_empty
        end

        it 'includes cicd.pipeline.run.url.full' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'cicd.pipeline.run.url.full', value: { stringValue: 'https://gitlab.com/project/-/pipelines/123' } }
          )
        end

        it 'includes cicd.pipeline.run.duration' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'cicd.pipeline.run.duration', value: { intValue: 300000 } }
          )
        end

        it 'includes cicd.pipeline.run.queued_duration' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'cicd.pipeline.run.queued_duration', value: { intValue: 30000 } }
          )
        end

        it 'includes cicd.pipeline.trigger.type mapped via map_pipeline_trigger_type' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'push' } }
          )
        end

        context 'for cicd.pipeline.trigger.type mapping via CicdSemconv' do
          it 'maps push source to push' do
            pipeline_data[:object_attributes][:source] = 'push'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'push' } }
            )
          end

          it 'maps schedule source to schedule' do
            pipeline_data[:object_attributes][:source] = 'schedule'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'schedule' } }
            )
          end

          it 'maps web source to manual' do
            pipeline_data[:object_attributes][:source] = 'web'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'manual' } }
            )
          end

          it 'maps trigger source to manual' do
            pipeline_data[:object_attributes][:source] = 'trigger'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'manual' } }
            )
          end

          it 'maps api source to manual' do
            pipeline_data[:object_attributes][:source] = 'api'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'manual' } }
            )
          end

          it 'maps merge_request_event source to merge_request_event' do
            pipeline_data[:object_attributes][:source] = 'merge_request_event'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'merge_request_event' } }
            )
          end

          it 'maps external_pull_request_event source to pull_request_event' do
            pipeline_data[:object_attributes][:source] = 'external_pull_request_event'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'pull_request_event' } }
            )
          end

          it 'maps pipeline source to pipeline' do
            pipeline_data[:object_attributes][:source] = 'pipeline'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.trigger.type', value: { stringValue: 'pipeline' } }
            )
          end

          it 'omits cicd.pipeline.trigger.type for unknown source' do
            pipeline_data[:object_attributes][:source] = 'unknown_source'
            trigger_attrs = pipeline_log[:attributes].select do |attr|
              attr[:key] == 'cicd.pipeline.trigger.type'
            end
            expect(trigger_attrs).to be_empty
          end
        end

        it 'includes vcs.ref.head.protected' do
          expect(pipeline_log[:attributes]).to include(
            { key: 'vcs.ref.head.protected', value: { boolValue: true } }
          )
        end

        it 'sets vcs.ref.head.protected to false when ref is not protected' do
          pipeline_data[:object_attributes][:protected_ref] = false
          expect(pipeline_log[:attributes]).to include(
            { key: 'vcs.ref.head.protected', value: { boolValue: false } }
          )
        end

        context 'for cicd.pipeline.result via CicdSemconv' do
          it 'maps success to cicd.pipeline.result = success' do
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.result', value: { stringValue: 'success' } }
            )
          end

          it 'maps failed to cicd.pipeline.result = failure' do
            pipeline_data[:object_attributes][:status] = 'failed'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.result', value: { stringValue: 'failure' } }
            )
          end

          it 'maps canceled to cicd.pipeline.result = cancellation' do
            pipeline_data[:object_attributes][:status] = 'canceled'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.result', value: { stringValue: 'cancellation' } }
            )
          end

          it 'maps skipped to cicd.pipeline.result = skip' do
            pipeline_data[:object_attributes][:status] = 'skipped'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.result', value: { stringValue: 'skip' } }
            )
          end

          it 'omits cicd.pipeline.result when status has no mapped result' do
            pipeline_data[:object_attributes][:status] = 'running'
            result_attrs = pipeline_log[:attributes].select { |attr| attr[:key] == 'cicd.pipeline.result' }
            expect(result_attrs).to be_empty
          end
        end

        context 'for cicd.pipeline.run.state via CicdSemconv' do
          it 'maps running to cicd.pipeline.run.state = executing' do
            pipeline_data[:object_attributes][:status] = 'running'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.run.state', value: { stringValue: 'executing' } }
            )
          end

          it 'maps pending to cicd.pipeline.run.state = pending' do
            pipeline_data[:object_attributes][:status] = 'pending'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.run.state', value: { stringValue: 'pending' } }
            )
          end

          it 'maps waiting_for_resource to cicd.pipeline.run.state = pending' do
            pipeline_data[:object_attributes][:status] = 'waiting_for_resource'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.run.state', value: { stringValue: 'pending' } }
            )
          end

          it 'maps preparing to cicd.pipeline.run.state = pending' do
            pipeline_data[:object_attributes][:status] = 'preparing'
            expect(pipeline_log[:attributes]).to include(
              { key: 'cicd.pipeline.run.state', value: { stringValue: 'pending' } }
            )
          end

          it 'omits cicd.pipeline.run.state when status has no mapped state' do
            pipeline_data[:object_attributes][:status] = 'success'
            state_attrs = pipeline_log[:attributes].select { |attr| attr[:key] == 'cicd.pipeline.run.state' }
            expect(state_attrs).to be_empty
          end
        end
      end

      describe 'job log semconv attributes' do
        let(:job_log) do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          log_records.find { |log| log[:body][:stringValue].include?('test-job') }
        end

        let(:failed_job_log) do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          log_records.find { |log| log[:body][:stringValue].include?('failed-job') }
        end

        it 'includes cicd.pipeline.task.name' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.name', value: { stringValue: 'test-job' } }
          )
        end

        it 'includes cicd.pipeline.task.run.id as string' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.id', value: { stringValue: '1' } }
          )
        end

        it 'includes cicd.pipeline.task.type from stage' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.type', value: { stringValue: 'test' } }
          )
        end

        it 'includes cicd.pipeline.task.run.result for terminal job statuses' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.result', value: { stringValue: 'success' } }
          )

          expect(failed_job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.result', value: { stringValue: 'failure' } }
          )
        end

        it 'omits cicd.pipeline.task.run.result when status has no mapped result' do
          pipeline_data[:builds].first[:status] = 'running'
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          running_job_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }
          result_attrs = running_job_log[:attributes].select { |attr| attr[:key] == 'cicd.pipeline.task.run.result' }
          expect(result_attrs).to be_empty
        end

        it 'omits cicd.pipeline.task.run.state when status has no mapped state' do
          # 'success' is not in TASK_RUN_STATE_MAP
          state_attrs = job_log[:attributes].select { |attr| attr[:key] == 'cicd.pipeline.task.run.state' }
          expect(state_attrs).to be_empty
        end

        it 'includes cicd.pipeline.task.run.state for in-progress job statuses' do
          pipeline_data[:builds].first[:status] = 'running'
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          running_job_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }
          expect(running_job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.state', value: { stringValue: 'executing' } }
          )
        end

        it 'includes cicd.pipeline.task.run.allow_failure' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.allow_failure', value: { boolValue: false } }
          )

          expect(failed_job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.allow_failure', value: { boolValue: true } }
          )
        end

        it 'includes cicd.pipeline.task.run.failure_reason when present' do
          expect(failed_job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.failure_reason', value: { stringValue: 'script_failure' } }
          )
        end

        it 'omits cicd.pipeline.task.run.failure_reason when not present' do
          failure_attrs = job_log[:attributes].select { |attr| attr[:key] == 'cicd.pipeline.task.run.failure_reason' }
          expect(failure_attrs).to be_empty
        end

        it 'includes cicd.pipeline.task.trigger.type as automatic when not manual' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.trigger.type', value: { stringValue: 'automatic' } }
          )
        end

        it 'includes cicd.pipeline.task.trigger.type as manual when manual' do
          expect(failed_job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.trigger.type', value: { stringValue: 'manual' } }
          )
        end

        it 'includes cicd.pipeline.task.run.queue_duration' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.queue_duration', value: { intValue: 5000 } }
          )

          expect(failed_job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.queue_duration', value: { intValue: 2000 } }
          )
        end

        it 'includes cicd.pipeline.task.run.duration' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.duration', value: { intValue: 120000 } }
          )

          expect(failed_job_log[:attributes]).to include(
            { key: 'cicd.pipeline.task.run.duration', value: { intValue: 60000 } }
          )
        end
      end

      describe 'runner/worker semconv attributes' do
        let(:job_log) do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          log_records.find { |log| log[:body][:stringValue].include?('test-job') }
        end

        it 'includes cicd.worker.id as string' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.worker.id', value: { stringValue: '1' } }
          )
        end

        it 'includes cicd.worker.tags' do
          expect(job_log[:attributes]).to include(
            { key: 'cicd.worker.tags', value: { arrayValue: { values: [
              { stringValue: 'docker' },
              { stringValue: 'linux' }
            ] } } }
          )
        end

        it 'does not include worker attributes when runner is absent' do
          result = converter.convert
          log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
          failed_job_log = log_records.find { |log| log[:body][:stringValue].include?('failed-job') }

          worker_attrs = failed_job_log[:attributes].select { |attr| attr[:key].start_with?('cicd.worker.') }
          expect(worker_attrs).to be_empty
        end
      end
    end

    it 'includes environment attributes correctly' do
      test_cases = [
        {
          environment: { name: 'production', action: 'start' },
          expected_name: 'production',
          expected_action: 'start'
        },
        {
          environment: { name: nil, action: nil },
          expected_name: '',
          expected_action: ''
        }
      ]

      test_cases.each do |test_case|
        pipeline_data[:builds].first[:environment] = test_case[:environment]
        result = converter.convert
        log_records = result[:resourceLogs].first[:scopeLogs].first[:logRecords]
        job_log = log_records.find { |log| log[:body][:stringValue].include?('test-job') }
        attributes = job_log[:attributes]

        expect(attributes).to include(
          { key: 'job.environment.name', value: { stringValue: test_case[:expected_name] } },
          { key: 'job.environment.action', value: { stringValue: test_case[:expected_action] } }
        )
      end
    end
  end

  describe '#build_environment_attributes' do
    it 'returns environment attributes correctly' do
      test_cases = [
        {
          build: { name: 'test-job', status: 'success' },
          expected: []
        },
        {
          build: {
            name: 'test-job',
            status: 'success',
            environment: {
              name: 'staging',
              action: 'stop'
            }
          },
          expected: [
            { key: 'job.environment.name', value: { stringValue: 'staging' } },
            { key: 'job.environment.action', value: { stringValue: 'stop' } }
          ]
        }
      ]

      aggregate_failures do
        test_cases.each do |test_case|
          result = converter.send(:build_environment_attributes, test_case[:build])
          expect(result).to eq(test_case[:expected])
        end
      end
    end
  end

  describe '#map_severity' do
    it 'maps status to severity number correctly' do
      test_cases = {
        'success' => 9,
        'failed' => 17,
        'canceled' => 13,
        'running' => 5,
        'pending' => 5,
        nil => 5
      }

      aggregate_failures do
        test_cases.each do |status, expected_severity|
          expect(converter.send(:map_severity, status)).to eq(expected_severity),
            "Expected #{status.inspect} to map to #{expected_severity}"
        end
      end
    end
  end

  describe '#map_severity_text' do
    it 'maps status to severity text correctly' do
      test_cases = {
        'success' => 'INFO',
        'failed' => 'ERROR',
        'canceled' => 'WARN',
        'running' => 'DEBUG',
        'pending' => 'DEBUG',
        nil => 'DEBUG'
      }

      aggregate_failures do
        test_cases.each do |status, expected_severity|
          expect(converter.send(:map_severity_text, status)).to eq(expected_severity),
            "Expected #{status.inspect} to map to #{expected_severity}"
        end
      end
    end
  end

  describe '#time_to_nanoseconds' do
    it 'returns 0 for blank values' do
      aggregate_failures do
        expect(converter.send(:time_to_nanoseconds, nil)).to eq(0)
        expect(converter.send(:time_to_nanoseconds, '')).to eq(0)
      end
    end

    it 'converts ActiveSupport::TimeWithZone timestamps to nanoseconds' do
      time = ActiveSupport::TimeZone['UTC'].parse('2023-01-01T10:00:00Z')
      expected_nanoseconds = (time.to_f * 1_000_000_000).to_i

      expect(converter.send(:time_to_nanoseconds, time)).to eq(expected_nanoseconds)
    end

    it 'returns 0 for non-TimeWithZone objects' do
      time = Time.parse('2023-01-01T10:00:00Z')

      expect(converter.send(:time_to_nanoseconds, time)).to eq(0)
    end
  end

  describe '#compact_attributes' do
    it 'removes nil entries' do
      attrs = [
        { key: 'keep', value: { stringValue: 'value' } },
        nil,
        { key: 'also_keep', value: { intValue: 1 } }
      ]

      result = converter.send(:compact_attributes, attrs)
      expect(result).to eq([
        { key: 'keep', value: { stringValue: 'value' } },
        { key: 'also_keep', value: { intValue: 1 } }
      ])
    end

    it 'removes attributes with blank string values' do
      attrs = [
        { key: 'present', value: { stringValue: 'hello' } },
        { key: 'empty', value: { stringValue: '' } },
        { key: 'nil_string', value: { stringValue: nil } }
      ]

      result = converter.send(:compact_attributes, attrs)
      expect(result).to eq([
        { key: 'present', value: { stringValue: 'hello' } }
      ])
    end

    it 'preserves non-string value types regardless of value' do
      attrs = [
        { key: 'zero_int', value: { intValue: 0 } },
        { key: 'false_bool', value: { boolValue: false } }
      ]

      result = converter.send(:compact_attributes, attrs)
      expect(result).to eq(attrs)
    end
  end
end
