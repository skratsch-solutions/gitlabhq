# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin updates network settings', :request_store, :enable_admin_mode,
  feature_category: :rate_limiting do
  include StubENV
  include Features::SettingsHelpers

  let_it_be(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
    visit network_admin_application_settings_path
  end

  it 'changes Outbound requests settings', :aggregate_failures do
    within_testid('outbound-requests-content') do
      click_unchecked_field(s_('OutboundRequests|Allow requests to the local network from webhooks and integrations'))
      click_checked_field(s_('OutboundRequests|Allow requests to the local network from system hooks'))
      click_checked_field(s_('OutboundRequests|Enforce DNS-rebinding attack protection'))

      expect_save_settings

      expect_field_checked(s_('OutboundRequests|Allow requests to the local network from webhooks and integrations'))
      expect_field_unchecked(s_('OutboundRequests|Allow requests to the local network from system hooks'))
      expect_field_unchecked(s_('OutboundRequests|Enforce DNS-rebinding attack protection'))
    end
  end

  it 'changes User and IP rate limits settings', :aggregate_failures do
    within_testid('ip-limits-content') do
      click_unchecked_field(_('Enable unauthenticated API request rate limit'))
      fill_field_with_new_value(_('Maximum unauthenticated API requests per rate limit period per IP'), '100')
      fill_field_with_new_value(_('Unauthenticated API rate limit period in seconds'), '200')

      click_unchecked_field(_('Enable unauthenticated web request rate limit'))
      fill_field_with_new_value(_('Maximum unauthenticated web requests per rate limit period per IP'), '300')
      fill_field_with_new_value(_('Unauthenticated web rate limit period in seconds'), '400')

      click_unchecked_field(_('Enable authenticated API request rate limit'))
      fill_field_with_new_value(_('Maximum authenticated API requests per rate limit period per user'), '500')
      fill_field_with_new_value(_('Authenticated API rate limit period in seconds'), '600')

      click_unchecked_field(_('Enable authenticated web request rate limit'))
      fill_field_with_new_value(_('Maximum authenticated web requests per rate limit period per user'), '700')
      fill_field_with_new_value(_('Authenticated web rate limit period in seconds'), '800')

      fill_field_with_new_value("Maximum authenticated requests to project/:id/jobs per minute", '1000')

      fill_field_with_new_value(_('Plain-text response to send to clients that hit a rate limit'), 'Custom message')

      expect_save_settings

      expect_field_checked(_('Enable unauthenticated API request rate limit'))
      expect_field_value(_('Maximum unauthenticated API requests per rate limit period per IP'), '100')
      expect_field_value(_('Unauthenticated API rate limit period in seconds'), '200')

      expect_field_checked(_('Enable unauthenticated web request rate limit'))
      expect_field_value(_('Maximum unauthenticated web requests per rate limit period per IP'), '300')
      expect_field_value(_('Unauthenticated web rate limit period in seconds'), '400')

      expect_field_checked(_('Enable authenticated API request rate limit'))
      expect_field_value(_('Maximum authenticated API requests per rate limit period per user'), '500')
      expect_field_value(_('Authenticated API rate limit period in seconds'), '600')

      expect_field_checked(_('Enable authenticated web request rate limit'))
      expect_field_value(_('Maximum authenticated web requests per rate limit period per user'), '700')
      expect_field_value(_('Authenticated web rate limit period in seconds'), '800')

      expect_field_value("Maximum authenticated requests to project/:id/jobs per minute", '1000')

      expect_field_value(_('Plain-text response to send to clients that hit a rate limit'), 'Custom message')
    end
  end

  it 'changes authenticated Git HTTP rate limits settings', :aggregate_failures do
    within_testid('git-http-limits-settings') do
      click_unchecked_field(_('Enable authenticated Git HTTP request rate limit'))
      fill_field_with_new_value(
        _('Maximum authenticated Git HTTP requests per period per user'),
        (ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_LIMIT + 1).to_s
      )
      fill_field_with_new_value(
        _('Authenticated Git HTTP rate limit period in seconds'),
        (ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_PERIOD + 2).to_s
      )

      expect_save_settings

      expect_field_checked(_('Enable authenticated Git HTTP request rate limit'))
      expect_field_value(
        _('Maximum authenticated Git HTTP requests per period per user'),
        (ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_LIMIT + 1).to_s
      )
      expect_field_value(
        _('Authenticated Git HTTP rate limit period in seconds'),
        (ApplicationSetting::DEFAULT_AUTHENTICATED_GIT_HTTP_PERIOD + 2).to_s
      )
    end
  end

  it 'changes Issues rate limits settings' do
    within_testid('issue-limits-settings') do
      fill_field_with_new_value(_('Maximum number of requests per minute'), '0')

      expect_save_settings

      expect_field_value(_('Maximum number of requests per minute'), '0')
    end
  end

  it 'changes Pipelines rate limits settings', :aggregate_failures do
    within_testid('pipeline-limits-settings') do
      fill_field_with_new_value(_('Maximum number of requests per project, sha and user. Resets after 1 minute.'), '10')
      fill_field_with_new_value(_('Maximum number of requests for a user. Resets after 1 minute.'), '100')

      expect_save_settings

      expect_field_value(_('Maximum number of requests per project, sha and user. Resets after 1 minute.'), '10')
      expect_field_value(_('Maximum number of requests for a user. Resets after 1 minute.'), '100')
    end
  end

  it 'changes gitlab shell operation limits settings' do
    within_testid('gitlab-shell-operation-limits') do
      fill_field_with_new_value(s_('ShellOperations|Maximum number of Git operations per minute'), '100')

      expect_save_settings

      expect_field_value(s_('ShellOperations|Maximum number of Git operations per minute'), '100')
    end
  end

  shared_examples 'API rate limit setting' do
    it 'changes the rate limits settings' do
      within_testid(network_settings_section) do
        fill_field_with_new_value(rate_limit_field, '1234')

        expect_save_settings

        expect_field_value(rate_limit_field, '1234')
      end
    end
  end

  describe 'users API rate limits' do
    let_it_be(:network_settings_section) { 'users-api-limits-settings' }

    context 'for GET /users:id API requests', :aggregate_failures do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'), api_name: 'GET /users/:id',
          timeframe: '10 minutes')
      end

      let(:application_setting_key) { :users_get_by_id_limit }

      it 'changes Users API rate limits settings', :aggregate_failures do
        within_testid('users-api-limits-settings') do
          fill_field_with_new_value(rate_limit_field, '0')
          fill_in _('Excluded users'), with: 'someone, someone_else'

          expect_save_settings

          expect_field_value(rate_limit_field, '0')
          expect_field_value(_('Excluded users'), "someone\nsomeone_else")
        end
      end
    end

    context 'for GET /users/:id/followers API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/followers', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_followers }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:id/following API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/following', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_following }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:user_id/status API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/status', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_status }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:user_id/keys API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/keys', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_ssh_keys }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:id/keys/:key_id API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/keys/:key_id', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_ssh_key }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:id/gpg_keys API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/gpg_keys', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_gpg_keys }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:id/gpg_keys/:key_id API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:id/gpg_keys/:key_id', timeframe: 'minute')
      end

      let(:application_setting_key) { :users_api_limit_gpg_key }

      it_behaves_like 'API rate limit setting'
    end
  end

  describe 'organizations API rate limits' do
    let_it_be(:network_settings_section) { 'organizations-api-limits-settings' }

    context 'for POST /organizations API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user'), api_name: 'POST /organizations',
          timeframe: 'minute')
      end

      let(:application_setting_key) { :create_organization_api_limit }

      it_behaves_like 'API rate limit setting'
    end
  end

  describe 'groups API rate limits' do
    let_it_be(:network_settings_section) { 'groups-api-limits-settings' }

    context 'for unauthenticated GET /groups API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :groups_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /groups/:id API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :group_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /groups/:id/projects API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/projects', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :group_projects_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /groups/:id/groups/shared API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/groups/shared', timeframe: 'minute')
      end

      let(:application_setting_key) { :group_shared_groups_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /groups/:id/invited_groups API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /groups/:id/invited_groups', timeframe: 'minute')
      end

      let(:application_setting_key) { :group_invited_groups_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for POST /groups/:id/archive API requests' do
      let(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name1} and %{api_name2} APIs per %{timeframe} per user or IP address'),
          api_name1: 'POST /groups/:id/archive', api_name2: 'POST /groups/:id/unarchive', timeframe: 'minute')
      end

      let(:application_setting_key) { :group_archive_unarchive_api_limit }

      it_behaves_like 'API rate limit setting'
    end
  end

  describe 'projects API rate limits' do
    let_it_be(:network_settings_section) { 'projects-api-limits-settings' }

    context 'for unauthenticated GET /projects API requests' do
      let_it_be(:rate_limit_field) do
        format(
          _('Maximum requests to the %{api_name} API per %{timeframe} per IP address for unauthenticated requests'),
          api_name: 'GET /projects',
          timeframe: '10 minutes'
        )
      end

      let_it_be(:application_setting_key) { :projects_api_rate_limit_unauthenticated }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /projects API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user for authenticated requests'),
          api_name: 'GET /projects', timeframe: '10 minutes')
      end

      let_it_be(:application_setting_key) { :projects_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /projects/:id API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :project_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /projects/:id/members/all API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id/members/all', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :project_members_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /projects/:id/invited_groups API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /projects/:id/invited_groups', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :project_invited_groups_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:user_id/projects API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/projects', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :user_projects_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:user_id/contributed_projects API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/contributed_projects', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :user_contributed_projects_api_limit }

      it_behaves_like 'API rate limit setting'
    end

    context 'for GET /users/:user_id/starred_projects API requests' do
      let_it_be(:rate_limit_field) do
        format(_('Maximum requests to the %{api_name} API per %{timeframe} per user or IP address'),
          api_name: 'GET /users/:user_id/starred_projects', timeframe: 'minute')
      end

      let_it_be(:application_setting_key) { :user_starred_projects_api_limit }

      it_behaves_like 'API rate limit setting'
    end
  end

  shared_examples 'regular throttle rate limit settings' do
    it 'changes rate limit settings', :aggregate_failures do
      within_testid(selector) do
        click_unchecked_field(_('Enable unauthenticated API request rate limit'))
        fill_field_with_new_value(_('Maximum unauthenticated API requests per rate limit period per IP'), '12')
        fill_field_with_new_value(_('Unauthenticated API rate limit period in seconds'), '34')

        click_unchecked_field(_('Enable authenticated API request rate limit'))
        fill_field_with_new_value(_('Maximum authenticated API requests per rate limit period per user'), '56')
        fill_field_with_new_value(_('Authenticated API rate limit period in seconds'), '78')

        expect_save_settings

        expect_field_checked(_('Enable unauthenticated API request rate limit'))
        expect_field_value(_('Maximum unauthenticated API requests per rate limit period per IP'), '12')
        expect_field_value(_('Unauthenticated API rate limit period in seconds'), '34')

        expect_field_checked(_('Enable authenticated API request rate limit'))
        expect_field_value(_('Maximum authenticated API requests per rate limit period per user'), '56')
        expect_field_value(_('Authenticated API rate limit period in seconds'), '78')
      end
    end
  end

  context 'for Package Registry API rate limits' do
    let(:selector) { 'packages-limits-settings' }
    let(:fragment) { :packages_api }

    include_examples 'regular throttle rate limit settings'
  end

  context 'for Files API rate limits' do
    let(:selector) { 'files-limits-settings' }
    let(:fragment) { :files_api }

    include_examples 'regular throttle rate limit settings'
  end

  context 'for Deprecated API rate limits' do
    let(:selector) { 'deprecated-api-rate-limits-settings' }
    let(:fragment) { :deprecated_api }

    include_examples 'regular throttle rate limit settings'
  end

  it 'changes search rate limits', :aggregate_failures do
    within_testid('search-limits-settings') do
      fill_field_with_new_value(_('Maximum number of requests per minute for an authenticated user'), '98')
      fill_field_with_new_value(_('Maximum number of requests per minute for an unauthenticated IP address'), '76')

      expect_save_settings

      expect_field_value(_('Maximum number of requests per minute for an authenticated user'), '98')
      expect_field_value(_('Maximum number of requests per minute for an unauthenticated IP address'), '76')
    end
  end
end
