# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../support/tmpdir'
require_relative '../../../../lib/gitlab/principles_distiller/sync'

# AutoMr is mixed into Sync via `include`, so its methods only mean
# anything on a Sync instance. The file path (sync/auto_mr_spec.rb)
# signals the subject matter; the described_class reflects what the
# tests actually exercise.
RSpec.describe Gitlab::PrinciplesDistiller::Sync do # rubocop:disable RSpec/SpecFilePathFormat -- subject-matter grouping (AutoMr) overrides path/class match
  include TmpdirHelper

  # rubocop:disable RSpec/EnvAssignment -- ENV assignment is necessary in `around` blocks; stub_env requires `allow` which is not available outside `before`
  around do |example|
    original_branch = ENV['CI_DEFAULT_BRANCH']
    ENV['CI_DEFAULT_BRANCH'] ||= 'master'
    example.run
  ensure
    ENV['CI_DEFAULT_BRANCH'] = original_branch
  end
  # rubocop:enable RSpec/EnvAssignment

  let(:tmpdir) { mktmpdir }
  let(:sync) { described_class.new }

  describe '.principle_diff_section' do
    subject(:section) { sync.principle_diff_section(name, affected_entry, default_branch) }

    let(:name) { 'code-review' }
    let(:default_branch) { 'master' }
    let(:project_url) { 'https://gitlab.com/gitlab-org/gitlab' }

    before do
      allow(sync.workflow).to receive_messages(
        gitlab_host: 'https://gitlab.com',
        catalog_project_path: 'gitlab-org/gitlab'
      )
      # Stub git interactions so tests don't shell out.
      allow(sync).to receive_messages(
        distillation_base_sha: 'abcdef1234567890abcdef1234567890abcdef12',
        compute_principle_diff: [nil, false]
      )
    end

    context 'with sources and a prior SHA' do
      let(:affected_entry) do
        {
          changed_sources: [
            { 'path' => 'doc/development/code_review.md' },
            { 'path' => 'doc/development/contributing/merge_request_workflow.md' }
          ],
          prior_sha: '9ab16c7588f7d32fdb6d509a70bae72309346826'
        }
      end

      it 'starts with the principle name as a Markdown subheading' do
        expect(section).to start_with('#### `code-review`')
      end

      it 'includes a commits link per source path', :aggregate_failures do
        expect(section).to include(
          "- [`doc/development/code_review.md`](#{project_url}/-/commits/master/doc/development/code_review.md)"
        )
        expect(section).to include(
          "- [`doc/development/contributing/merge_request_workflow.md`](" \
            "#{project_url}/-/commits/master/doc/development/contributing/merge_request_workflow.md)"
        )
      end

      it 'wraps the file list in a <details> block with a count summary' do
        expect(section).to include('<details><summary>Source files (2)</summary>')
        expect(section).to include('</details>')
      end

      it 'does NOT include the broad project-wide compare link (it was unhelpful at scale)' do
        expect(section).not_to include('/-/compare/')
        expect(section).not_to include('Compare SSOT changes')
      end
    end

    context 'when a per-principle SSOT diff is available' do
      let(:affected_entry) do
        {
          changed_sources: [{ 'path' => 'doc/development/code_review.md' }],
          prior_sha: '9ab16c7588f7d32fdb6d509a70bae72309346826'
        }
      end

      let(:diff_text) { "diff --git a/doc/development/code_review.md b/doc/development/code_review.md\n+new line\n" }

      before do
        allow(sync).to receive(:compute_principle_diff).and_return([diff_text, false])
      end

      it 'embeds the diff in a <details> block with both range SHAs in the summary', :aggregate_failures do
        expect(section).to include('<details><summary>SSOT diff since previous distillation ' \
          "(9ab16c7588f7 \u2192 abcdef123456)</summary>")
        expect(section).to include('````diff')
        expect(section).to include(diff_text.chomp)
      end

      it 'shows the resolved current-tip SHA (not the branch name) so the range stays meaningful' do
        expect(section).not_to match(/SSOT diff since previous distillation \([0-9a-f]+ \u2192 master\)/)
      end

      it 'uses a 4-backtick fence so embedded ``` blocks in SSOT files do not close it prematurely' do
        expect(section).to include('````diff')
        expect(section).to include('````')
      end
    end

    context 'when the diff is truncated' do
      let(:affected_entry) do
        {
          changed_sources: [{ 'path' => 'doc/development/code_review.md' }],
          prior_sha: '9ab16c7588f7d32fdb6d509a70bae72309346826'
        }
      end

      before do
        allow(sync).to receive(:compute_principle_diff).and_return(["a long diff\n", true])
      end

      it 'appends a truncation footer pointing at the per-file links' do
        expect(section).to include('diff truncated at')
        expect(section).to include('per-file commit-history links')
      end
    end

    context 'without a prior SHA' do
      let(:affected_entry) do
        { changed_sources: [{ 'path' => 'doc/foo.md' }], prior_sha: nil }
      end

      it 'still includes the per-file commits link' do
        expect(section).to include("- [`doc/foo.md`](#{project_url}/-/commits/master/doc/foo.md)")
      end

      it 'omits the diff section' do
        expect(section).not_to include('SSOT diff since previous distillation')
      end
    end

    context 'with no sources and no prior SHA (e.g. forced full re-distillation)' do
      let(:affected_entry) { { changed_sources: [], prior_sha: nil } }

      it 'still emits the principle heading' do
        expect(section).to include('#### `code-review`')
      end

      it 'does not crash on empty data' do
        expect { section }.not_to raise_error
      end
    end
  end

  describe '.truncate_diff' do
    it 'returns the input unchanged if both caps are honored' do
      text = "line1\nline2\n"

      result, truncated = sync.truncate_diff(text)

      expect(result).to eq(text)
      expect(truncated).to be(false)
    end

    it 'caps to DIFF_MAX_LINES when the line count exceeds the limit' do
      stub_const("#{described_class}::AutoMr::DIFF_MAX_LINES", 3)
      stub_const("#{described_class}::AutoMr::DIFF_MAX_BYTES", 10_000)
      text = "#{(1..10).map { |i| "line#{i}" }.join("\n")}\n"

      result, truncated = sync.truncate_diff(text)

      expect(result.lines.size).to eq(3)
      expect(truncated).to be(true)
    end

    it 'caps to DIFF_MAX_BYTES and trims back to a newline boundary' do
      stub_const("#{described_class}::AutoMr::DIFF_MAX_LINES", 1000)
      stub_const("#{described_class}::AutoMr::DIFF_MAX_BYTES", 12)
      text = "abcdefgh\nijklmn\nopq\n"

      result, truncated = sync.truncate_diff(text)

      expect(result).to eq("abcdefgh\n")
      expect(truncated).to be(true)
    end
  end

  describe '.find_open_mr_iid' do
    # find_open_mr_iid is a private AutoMr helper. Specs reach it via send
    # and stub the Net::HTTP transport directly (the same seam the
    # GraphqlClient spec uses).
    subject(:iid) do
      sync.send(:find_open_mr_iid, 'gitlab-org%2Fgitlab', 'feature-branch', 'api-token')
    end

    let(:fake_response) { instance_double(Net::HTTPResponse, code: '200', body: response_body) }
    let(:http_instance) { instance_double(Net::HTTP) }
    let(:captured_request) { [] }

    before do
      allow(sync.workflow).to receive(:gitlab_host).and_return('https://gitlab.com')
      allow(Net::HTTP).to receive(:new).and_return(http_instance)
      allow(http_instance).to receive(:use_ssl=)
      allow(http_instance).to receive(:read_timeout=)
      allow(http_instance).to receive(:request) do |request|
        captured_request << request
        fake_response
      end
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(http_success)
    end

    context 'when the API returns one open MR' do
      let(:http_success) { true }
      let(:response_body) { '[{"iid":42}]' }

      it 'returns the iid' do
        expect(iid).to eq(42)
      end
    end

    context 'when the API returns an empty array' do
      let(:http_success) { true }
      let(:response_body) { '[]' }

      it 'returns nil' do
        expect(iid).to be_nil
      end
    end

    context 'when the API returns a non-2xx response' do
      let(:http_success) { false }
      let(:response_body) { 'Internal Server Error' }

      it 'returns nil' do
        expect(iid).to be_nil
      end
    end

    context 'on URL construction' do
      let(:http_success) { true }
      let(:response_body) { '[]' }

      it 'sends order_by=created_at and sort=desc so the result is deterministic',
        :aggregate_failures do
        iid

        query = captured_request.first.uri.query
        expect(query).to include('state=opened')
        expect(query).to include('source_branch=feature-branch')
        expect(query).to include('order_by=created_at')
        expect(query).to include('sort=desc')
      end

      it 'sends the PRIVATE-TOKEN header' do
        iid

        expect(captured_request.first['PRIVATE-TOKEN']).to eq('api-token')
      end
    end
  end

  describe '.prefetch_prior_shas!' do
    # prefetch_prior_shas! is private; reach it via send. We stub
    # `sha_present_locally?` and `system` to avoid touching real git.
    subject(:prefetch) { sync.send(:prefetch_prior_shas!, affected) }

    before do
      Gitlab::PrinciplesDistiller::Workspace.path = '/tmp/workspace'
      allow(sync).to receive(:system).and_return(true)
    end

    context 'with no prior SHAs in affected' do
      let(:affected) { { 'qa' => { prior_sha: nil } } }

      it 'is a no-op' do
        prefetch

        expect(sync).not_to have_received(:system)
      end
    end

    context 'when all prior SHAs are already present locally' do
      let(:affected) do
        { 'qa' => { prior_sha: 'abc123' }, 'backend' => { prior_sha: 'def456' } }
      end

      before do
        allow(sync).to receive(:sha_present_locally?).and_return(true)
      end

      it 'does not invoke git fetch' do
        prefetch

        expect(sync).not_to have_received(:system)
          .with('git', anything, anything, 'fetch', any_args)
      end
    end

    context 'when prior SHAs are missing locally' do
      let(:affected) do
        { 'qa' => { prior_sha: 'abc123' }, 'backend' => { prior_sha: 'def456' } }
      end

      before do
        allow(sync).to receive(:sha_present_locally?).and_return(false)
      end

      it 'invokes git fetch --depth=1 origin <sha> for each missing SHA' do
        prefetch

        expect(sync).to have_received(:system)
          .with('git', '-C', '/tmp/workspace', 'fetch', '--depth=1', 'origin', 'abc123', any_args)
        expect(sync).to have_received(:system)
          .with('git', '-C', '/tmp/workspace', 'fetch', '--depth=1', 'origin', 'def456', any_args)
      end
    end

    context 'when affected has duplicate prior SHAs' do
      let(:affected) do
        {
          'qa' => { prior_sha: 'abc123' },
          'backend' => { prior_sha: 'abc123' },
          'security' => { prior_sha: 'abc123' }
        }
      end

      before do
        allow(sync).to receive(:sha_present_locally?).and_return(false)
      end

      it 'fetches each unique SHA only once' do
        prefetch

        expect(sync).to have_received(:system)
          .with('git', '-C', '/tmp/workspace', 'fetch', '--depth=1', 'origin', 'abc123', any_args)
          .once
      end
    end

    context 'when a fetch fails' do
      let(:affected) { { 'qa' => { prior_sha: 'abc123' } } }

      before do
        allow(sync).to receive(:sha_present_locally?).and_return(false)
        allow(sync).to receive(:system)
          .with('git', '-C', '/tmp/workspace', 'fetch', '--depth=1', 'origin', 'abc123', any_args)
          .and_return(false)
      end

      it 'warns but does not raise' do
        expect { prefetch }.to output(/could not fetch abc123/).to_stderr
      end
    end
  end

  describe '.push_remote_url' do
    # push_remote_url is a private AutoMr helper. Specs reach it via send.
    subject(:url) { sync.send(:push_remote_url, project_arg) }

    before do
      allow(sync.workflow).to receive(:gitlab_host).and_return(gitlab_host)
    end

    let(:gitlab_host) { 'https://gitlab.com' }

    context 'with CI_PROJECT_PATH set' do
      let(:project_arg) { '12345' }

      before do
        stub_const('ENV', 'CI_PROJECT_PATH' => 'gitlab-org/gitlab')
      end

      it 'returns a credential-free HTTPS URL using CI_PROJECT_PATH' do
        expect(url).to eq('https://gitlab.com/gitlab-org/gitlab.git')
      end
    end

    context 'without CI_PROJECT_PATH, when the project argument is a path' do
      let(:project_arg) { 'gitlab-org/gitlab' }

      before do
        stub_const('ENV', {})
      end

      it 'falls back to the path argument' do
        expect(url).to eq('https://gitlab.com/gitlab-org/gitlab.git')
      end
    end

    context 'without CI_PROJECT_PATH, when the project argument is numeric' do
      let(:project_arg) { '12345' }

      before do
        stub_const('ENV', {})
      end

      it 'aborts because numeric CI_PROJECT_ID alone is not enough' do
        expect { url }.to raise_error(SystemExit)
          .and output(/CI_PROJECT_PATH env var is required/).to_stderr
      end
    end

    context 'with a custom GITLAB_HOST' do
      let(:gitlab_host) { 'https://gitlab.example.com' }
      let(:project_arg) { '12345' }

      before do
        stub_const('ENV', 'CI_PROJECT_PATH' => 'group/repo')
      end

      it 'uses the host from workflow.gitlab_host' do
        expect(url).to eq('https://gitlab.example.com/group/repo.git')
      end
    end
  end

  describe '.create_branch_and_mr' do
    subject(:create_branch_and_mr) do
      sync.create_branch_and_mr(distilled_contents, affected, auto_mr_cfg)
    end

    let(:distilled_contents) do
      { 'qa' => "---\nsource_checksum: abc\n---\n# QA Principles\n" }
    end

    let(:affected) do
      {
        'qa' => {
          config: { 'sources' => [{ 'path' => 'doc/development/qa.md' }] },
          changed_sources: [{ 'path' => 'doc/development/qa.md' }],
          prior_sha: '1111111111111111111111111111111111111111'
        }
      }
    end

    let(:auto_mr_cfg) do
      {
        'branch_prefix' => 'docs-sync/principles',
        'title_template' => 'Update AI development principles from SSOT (%{date})',
        'labels' => %w[ai-agent documentation type::maintenance],
        'remove_source_branch' => true
      }
    end

    let(:mock_response) do
      instance_double(Net::HTTPResponse, is_a?: true, body: '{"web_url":"https://gitlab.com/foo"}', code: '201')
    end

    let(:received_body) { capture_post_body }

    before do
      stub_const('ENV', { 'GITLAB_API_TOKEN' => 'token', 'CI_PROJECT_ID' => 'gitlab-org/gitlab',
                          'CI_DEFAULT_BRANCH' => 'master', 'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
                          'CI_PROJECT_DIR' => '/tmp/workspace' })

      # Stub git invocations and the MR-create REST call so the test
      # exercises the full method body without touching the network or
      # the working tree.
      allow(File).to receive(:write)
      allow(sync).to receive_messages(
        system: true,
        distillation_base_sha: 'abcdef1234567890abcdef1234567890abcdef12'
      )
      allow(sync.workflow).to receive_messages(
        post_json: mock_response,
        gitlab_host: 'https://gitlab.com',
        catalog_project_path: 'gitlab-org/gitlab',
        default_branch: 'master'
      )
    end

    def capture_post_body
      captured = nil
      allow(sync.workflow).to receive(:post_json) do |_url, body:, **|
        captured = body
        mock_response
      end
      create_branch_and_mr
      captured
    end

    # Regression test for the `_affected`/`affected` rename bug
    # (https://gitlab.com/gitlab-org/gitlab/-/jobs/14279548642): the
    # method was renamed to `_affected` by rubocop autocorrect because
    # an earlier edit didn't yet reference it; subsequent edits used
    # the bare name and triggered a NameError at runtime in CI.
    it 'runs end-to-end without raising NameError on the affected parameter' do
      expect { create_branch_and_mr }.not_to raise_error
    end

    it 'invokes the MR-create REST call exactly once' do
      create_branch_and_mr

      expect(sync.workflow).to have_received(:post_json).once
    end

    context 'with a stubbed per-principle diff' do
      before do
        allow(sync).to receive(:compute_principle_diff)
          .and_return(["diff --git a/doc/development/qa.md b/doc/development/qa.md\n+new\n", false])
      end

      it 'embeds per-principle diff sections in the MR description', :aggregate_failures do
        expect(received_body[:description]).to include('#### `qa`')
        expect(received_body[:description]).to include('doc/development/qa.md')
        expect(received_body[:description]).to include('SSOT diff since previous distillation')
        expect(received_body[:description]).to include('````diff')
      end
    end

    it 'links the manifest and the CI job YAML in the "How this works" section',
      :aggregate_failures do
      expect(received_body[:description]).to include(
        '[`.ai/principles/manifest.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ai/principles/manifest.yml)'
      )
      expect(received_body[:description]).to include(
        '[scheduled CI job](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/sync-principles.gitlab-ci.yml)'
      )
    end

    context 'when CI_JOB_URL is set' do
      before do
        stub_const('ENV', {
          'GITLAB_API_TOKEN' => 'token', 'CI_PROJECT_ID' => 'gitlab-org/gitlab',
          'CI_DEFAULT_BRANCH' => 'master', 'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
          'CI_PROJECT_DIR' => '/tmp/workspace',
          'CI_JOB_URL' => 'https://gitlab.com/gitlab-org/gitlab/-/jobs/123'
        })
      end

      it 'links the generating CI job in the description' do
        expect(received_body[:description]).to include(
          'This MR was generated by https://gitlab.com/gitlab-org/gitlab/-/jobs/123'
        )
      end
    end

    it 'omits the generating-job line when CI_JOB_URL is unset' do
      expect(received_body[:description]).not_to include('This MR was generated by')
    end

    context 'with a custom auto_mr_cfg' do
      let(:auto_mr_cfg) do
        {
          'branch_prefix' => 'docs-sync/principles',
          'title_template' => 'Custom title %{date}',
          'labels' => %w[label-a label-b],
          'remove_source_branch' => false
        }
      end

      it 'applies auto_mr_cfg values to the MR title, labels, and remove_source_branch flag',
        :aggregate_failures do
        today = Time.now.utc.strftime('%Y%m%d')

        expect(received_body[:title]).to eq("Custom title #{today}")
        expect(received_body[:labels]).to eq('label-a,label-b')
        expect(received_body[:remove_source_branch]).to be(false)
      end
    end

    describe 'git push token handling' do
      # Capture the env hash passed to `system(env, 'git', ..., 'push', ...)`
      # without invoking the actual push.
      def capture_push_env
        captured = nil
        allow(sync).to receive(:system).and_call_original
        allow(sync).to receive(:system).and_return(true)
        allow(sync).to receive(:system) do |*args, **|
          captured = args[0] if args.size > 1 && args[0].is_a?(Hash) && args.include?('push')

          true
        end
        create_branch_and_mr
        captured
      end

      # Capture the URL argument passed to `system(env, 'git', ..., 'push', <url>, ...)`.
      def capture_push_url
        captured = nil
        allow(sync).to receive(:system).and_call_original
        allow(sync).to receive(:system).and_return(true)
        allow(sync).to receive(:system) do |*args, **|
          captured = args.find { |a| a.is_a?(String) && a.start_with?('https://') } if args.include?('push')

          true
        end
        create_branch_and_mr
        captured
      end

      context 'with no existing GIT_CONFIG_COUNT in the environment' do
        it 'passes a single host-scoped HTTP Basic Authorization header via env vars' do
          # 'b2F1dGgyOnRva2Vu' == Base64("oauth2:token").
          expect(capture_push_env).to eq(
            'GIT_CONFIG_COUNT' => '1',
            'GIT_CONFIG_KEY_0' => 'http.https://gitlab.com.extraHeader',
            'GIT_CONFIG_VALUE_0' => 'Authorization: Basic b2F1dGgyOnRva2Vu'
          )
        end

        it 'does not embed the token in the push URL' do
          expect(capture_push_url).to eq('https://gitlab.com/gitlab-org/gitlab.git')
        end

        it 'does not include the raw token in the header value' do
          expect(capture_push_env['GIT_CONFIG_VALUE_0']).not_to include('token')
        end
      end

      context 'when the parent environment already injects GIT_CONFIG_* entries' do
        # Simulates a GitLab Runner that pre-populates `GIT_CONFIG_COUNT`/
        # `GIT_CONFIG_KEY_*`/`GIT_CONFIG_VALUE_*` from CI variables.
        before do
          stub_const('ENV', {
            'GITLAB_API_TOKEN' => 'token',
            'CI_PROJECT_ID' => 'gitlab-org/gitlab',
            'CI_DEFAULT_BRANCH' => 'master',
            'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
            'CI_PROJECT_DIR' => '/tmp/workspace',
            'GIT_CONFIG_COUNT' => '2',
            'GIT_CONFIG_KEY_0' => 'http.proxy',
            'GIT_CONFIG_VALUE_0' => 'http://proxy.example:8080',
            'GIT_CONFIG_KEY_1' => 'core.sshCommand',
            'GIT_CONFIG_VALUE_1' => 'ssh -i /secrets/id_rsa'
          })
        end

        it 'appends at the next index without clobbering the existing count' do
          expect(capture_push_env).to eq(
            'GIT_CONFIG_COUNT' => '3',
            'GIT_CONFIG_KEY_2' => 'http.https://gitlab.com.extraHeader',
            'GIT_CONFIG_VALUE_2' => 'Authorization: Basic b2F1dGgyOnRva2Vu'
          )
        end
      end

      it 'aborts when the API token is empty' do
        stub_const('ENV', {
          'GITLAB_API_TOKEN' => '',
          'CI_PROJECT_ID' => 'gitlab-org/gitlab',
          'CI_DEFAULT_BRANCH' => 'master',
          'CI_PROJECT_PATH' => 'gitlab-org/gitlab',
          'CI_PROJECT_DIR' => '/tmp/workspace'
        })

        expect { capture_push_env }.to raise_error(SystemExit)
      end
    end

    context 'when create_mr fails mid-flow' do
      # Inject the failure at the REST POST that builds the MR. By this
      # point the publish branch has been created+checked out+pushed, so
      # the rescue path has real cleanup to do.
      before do
        allow(sync.workflow).to receive(:post_json).and_raise(StandardError, 'boom')
      end

      it 're-raises the original error' do
        expect { create_branch_and_mr }.to raise_error(StandardError, 'boom')
      end

      it 'attempts to check out the base branch during cleanup' do
        expect { create_branch_and_mr }.to raise_error(StandardError)

        expect(sync).to have_received(:system)
          .with('git', '-C', anything, 'checkout', 'master')
      end

      it 'attempts to delete the publish branch during cleanup' do
        expect { create_branch_and_mr }.to raise_error(StandardError)

        today = Time.now.utc.strftime('%Y%m%d')
        expect(sync).to have_received(:system)
          .with('git', '-C', anything, 'branch', '-D', "docs-sync/principles-#{today}")
      end

      context 'when the cleanup checkout itself fails' do
        before do
          # `system: true` is the default from the outer `before`. Override
          # it so the checkout step (the first cleanup `system` call after
          # the rescue) returns false, simulating "still on the publish
          # branch".
          allow(sync).to receive(:system).and_call_original
          allow(sync).to receive(:system)
            .with('git', '-C', anything, 'checkout', 'master').and_return(false)
          allow(sync).to receive(:system)
            .with(anything, anything, anything, anything, anything, anything, any_args).and_return(true)
          allow(sync).to receive(:system)
            .with('git', '-C', anything, 'branch', '-D', anything).and_return(true)
        end

        it 'warns about the failed checkout and still re-raises the original error' do
          expect { create_branch_and_mr }.to raise_error(StandardError, 'boom')
            .and output(/cleanup checkout to master failed/).to_stderr
        end
      end

      context 'when the cleanup branch deletion itself fails' do
        before do
          allow(sync).to receive(:system).and_call_original
          allow(sync).to receive(:system)
            .with(anything, anything, anything, anything, anything, anything, any_args).and_return(true)
          allow(sync).to receive(:system)
            .with('git', '-C', anything, 'checkout', 'master').and_return(true)
          allow(sync).to receive(:system)
            .with('git', '-C', anything, 'branch', '-D', anything).and_return(false)
        end

        it 'warns about the failed branch deletion and still re-raises the original error' do
          expect { create_branch_and_mr }.to raise_error(StandardError, 'boom')
            .and output(/cleanup deletion of branch.+failed/).to_stderr
        end
      end
    end
  end
end
