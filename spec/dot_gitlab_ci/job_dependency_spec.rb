# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ci jobs dependency', feature_category: :tooling,
  quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/34040#note_1991033499' do
  include RepoHelpers

  let_it_be(:group)   { create(:group, path: 'ci-org') }
  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project, :empty_repo, group: group, path: "ci") }
  let_it_be(:ci_glob) { Dir.glob("{.gitlab-ci.yml,.gitlab/**/*.yml}").freeze }
  let_it_be(:master_branch) { 'master' }

  let(:gitlab_com_variables_attributes_base) do
    [
      { key: 'CI_SERVER_HOST', value: 'gitlab.com' },
      { key: 'CI_PROJECT_NAMESPACE', value: 'gitlab-org/gitlab' }
    ]
  end

  let(:create_pipeline_service) { Ci::CreatePipelineService.new(project, user, ref: master_branch) }

  around(:all) do |example|
    with_net_connect_allowed { example.run } # creating pipeline requires network call to fetch templates
  end

  before_all do
    project.add_developer(user)

    sync_local_files_to_project(
      project,
      user,
      master_branch,
      files: ci_glob
    )
  end

  context 'with gitlab.com gitlab-org/gitlab master pipeline' do
    let(:content) do
      project.repository.blob_at(master_branch, '.gitlab-ci.yml').data
    end

    shared_examples 'master pipeline' do |trigger_source|
      subject(:pipeline) do
        create_pipeline_service
          .execute(trigger_source, dry_run: true, content: content, variables_attributes: variables_attributes)
          .payload
      end

      it 'is valid' do
        expect(pipeline.yaml_errors).to be nil
        expect(pipeline.status).to eq('created')
      end
    end

    context 'with default master pipeline' do
      let(:variables_attributes) { gitlab_com_variables_attributes_base }

      # Test: remove rules from .rails:rules:setup-test-env
      it_behaves_like 'master pipeline', :push
    end

    context 'with scheduled nightly' do
      let(:variables_attributes) do
        [
          *gitlab_com_variables_attributes_base,
          { key: 'SCHEDULE_TYPE', value: 'nightly' }
        ]
      end
      # .if-default-branch-schedule-nightly
      # included in .qa:rules:package-and-test-ce
      # used by e2e:package-and-test-ce
      # needs e2e-test-pipeline-generate
      # has rule .qa:rules:determine-e2e-tests

      # Test: I can remove this rule from .qa:rules:determine-e2e-tests
      # - <<: *if-dot-com-gitlab-org-schedule
      #   allow_failure: true
      it_behaves_like 'master pipeline', :schedule
    end

    context 'with scheduled maintenance' do
      let(:variables_attributes) do
        [
          *gitlab_com_variables_attributes_base,
          { key: 'SCHEDULE_TYPE', value: 'maintenance' }
        ]
      end

      it_behaves_like 'master pipeline', :schedule
    end
  end

  context 'with MR pipeline' do
    let(:mr_pipeline_variables_attributes_base) do
      [
        *gitlab_com_variables_attributes_base,
        { key: 'CI_MERGE_REQUEST_EVENT_TYPE', value: 'merged_result' },
        { key: 'CI_COMMIT_BRANCH', value: master_branch }
      ]
    end

    let(:source_branch) { "feature_branch_ci_#{SecureRandom.uuid}" }
    let(:target_branch) { master_branch }

    let(:merge_request) do
      create(:merge_request,
        source_project: project,
        source_branch: source_branch,
        target_project: project,
        target_branch: target_branch
      )
    end

    shared_examples 'merge request pipeline' do
      let(:variables_attributes) do
        [
          *mr_pipeline_variables_attributes_base,
          { key: 'CI_MERGE_REQUEST_LABELS', value: labels_string }
        ]
      end

      subject(:pipeline) do
        create_pipeline_service
          .execute(:push, dry_run: true, merge_request: merge_request, variables_attributes: variables_attributes)
          .payload
      end

      before do
        actions = changed_files.map do |file_path|
          {
            action: :create,
            file_path: file_path,
            content: 'content'
          }
        end

        project.repository.commit_files(
          user,
          branch_name: source_branch,
          message: 'changes files',
          actions: actions
        )
      end

      after do
        project.repository.delete_branch(source_branch)
      end

      it "creates a valid pipeline with expected job" do
        jobs = pipeline.stages.flat_map { |s| s.statuses.map(&:name) }.join("\n")
        expect(pipeline.yaml_errors).to be nil
        expect(pipeline.status).to eq('created')
        # to confirm that the dependent job is actually created and rule out false positives
        expect(jobs).to include(expected_job_name)
      end
    end

    # gitaly, db, backend patterns
    context "when unlabeled MR is changing GITALY_SERVER_VERSION" do
      let(:labels_string) { '' }
      let(:changed_files) { ['GITALY_SERVER_VERSION'] }
      let(:expected_job_name) { 'eslint' }

      it_behaves_like 'merge request pipeline'
    end

    # backstage-patterns, #.code-backstage-patterns and frontend ci pattern
    # Test: remove the following rules from `.frontend:rules:default-frontend-jobs`:
    # - <<: *if-merge-request-labels-run-all-rspec
    context 'when unlabled MR is changing Dangerfile, .gitlab/ci/frontend.gitlab-ci.yml' do
      let(:labels_string) { '' }
      let(:changed_files) { ['Dangerfile', '.gitlab/ci/frontend.gitlab-ci.yml'] }
      let(:expected_job_name) { 'rspec-all frontend_fixture' }

      it_behaves_like 'merge request pipeline'
    end

    # Test: remove the following rules from `.frontend:rules:default-frontend-jobs`:
    # - <<: *if-merge-request-labels-run-all-rspec
    context 'when MR labeled with `pipeline:run-all-rspec` is changing keeps/quarantine-test.rb' do
      let(:labels_string) { 'pipeline:run-all-rspec' }
      let(:changed_files) { ['keeps/quarantine-test.rb'] }
      let(:expected_job_name) { 'rspec-all frontend_fixture' }

      it_behaves_like 'merge request pipeline'
    end

    # code-patterns, code-backstage-patterns, backend patterns, code-qa-patterns
    context 'when MR labeled with `pipeline:expedite pipeline::expedited` is changing keeps/quarantine-test.rb' do
      let(:labels_string) { 'pipeline:expedite pipeline::expedited' }
      let(:changed_files) { ['keeps/quarantine-test.rb'] }
      let(:expected_job_name) { 'rails-production-server-boot-puma-cng' }

      it_behaves_like 'merge request pipeline'
    end

    # Reminder, we are NOT verifying the CI config from the remote stable branch
    # This test just mocks the target branch name to be a stable branch
    # the tested config is what's currently in the local .gitlab/ci folders

    # Test: remove the following rules from `.frontend:rules:default-frontend-jobs`:
    #   - <<: *if-default-refs
    #     changes: *code-backstage-patterns
    context 'when MR targeting a stable branch is changing keeps/' do
      let(:target_branch)           { '16-10-stable-ee' }
      let(:create_pipeline_service) { Ci::CreatePipelineService.new(project, user, ref: target_branch) }
      let(:labels_string)           { '' }
      let(:changed_files)           { ['keeps/quarantine-test.rb'] }
      let(:expected_job_name)       { 'rspec-all frontend_fixture' }

      before do
        sync_local_files_to_project(
          project,
          user,
          target_branch,
          files: ci_glob
        )
      end

      it_behaves_like 'merge request pipeline'
    end
  end
end
