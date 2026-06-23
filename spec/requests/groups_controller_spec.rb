# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsController, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  context 'token authentication' do
    context 'when public group' do
      let_it_be(:public_group) { create(:group, :public) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: true do
        let(:url) { group_path(public_group, format: :atom) }
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues atom', public_resource: true do
        let(:url) { issues_group_path(public_group, format: :atom) }
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues_calendar ics', public_resource: true do
        let(:url) { issues_group_calendar_url(public_group, format: :ics) }
      end
    end

    context 'when private group' do
      let_it_be(:private_group) { create(:group, :private) }

      it_behaves_like 'authenticates sessionless user for the request spec', 'show atom', public_resource: false, ignore_metrics: true do
        let(:url) { group_path(private_group, format: :atom) }

        before do
          private_group.add_maintainer(user)
        end
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues atom', public_resource: false, ignore_metrics: true do
        let(:url) { issues_group_path(private_group, format: :atom) }

        before do
          private_group.add_maintainer(user)
        end
      end

      it_behaves_like 'authenticates sessionless user for the request spec', 'issues_calendar ics', public_resource: false, ignore_metrics: true do
        let(:url) { issues_group_calendar_url(private_group, format: :ics) }

        before do
          private_group.add_maintainer(user)
        end
      end
    end
  end

  describe 'POST #preview_markdown' do
    let_it_be_with_reload(:group) { create(:group) }
    let_it_be(:developer) { create(:user, developer_of: group) }

    before do
      login_as(developer)
    end

    context 'when type is WorkItem' do
      let(:url) { group_preview_markdown_url(group, target_type: 'WorkItem', target_id: work_item.iid) }

      context 'when work item exists at the group level' do
        let(:work_item) { create(:work_item, :group_level, namespace: group) }

        it 'returns the markdown preview HTML', :aggregate_failures do
          post url, params: { text: '## Test markdown preview' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['body']).to include('Test markdown preview')
        end
      end
    end
  end

  describe 'GET #index' do
    context 'step-up authentication enforcement' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:user) { create(:user, owner_of: group) }
      let(:expected_success_status) { :found }

      subject(:make_request) { get groups_path }

      before do
        sign_in(user)
      end

      it_behaves_like 'does not enforce step-up authentication'
    end
  end

  describe 'GET #show' do
    context 'when group path contains format extensions' do
      where(:extension) { %w[.html .json] }

      with_them do
        let(:path) { 'my-group' }
        let(:group) { create(:group, path: "#{path}#{extension}") }
        let(:url) { group_path(group) }

        it 'resolves the group correctly' do
          get url

          expect(response).to have_gitlab_http_status(:ok)
          expect(assigns(:group)).to eq(group)
          expect(response).to render_template('groups/show')
        end

        it 'does not treat extension as format parameter' do
          get url

          expect(controller.params[:id]).to eq(group.to_param)
        end

        it 'does not resolve to the group without the extension' do
          create(:group, path: path) # group without the extension

          get url

          expect(assigns(:group)).to eq(group)
          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'step-up authentication enforcement' do
      let(:expected_success_status) { :ok }

      subject(:make_request) { get group_path(group) }

      context 'for private group' do
        let_it_be_with_reload(:group) { create(:group, :private) }
        let_it_be_with_reload(:user) { create(:user, owner_of: group) }

        context 'when user authenticated' do
          before do
            sign_in(user)
          end

          it_behaves_like 'enforces step-up authentication (request spec)'
        end
      end

      context 'for public group' do
        let_it_be_with_reload(:group) { create(:group) }
        let_it_be_with_reload(:user) { create(:user, owner_of: group) }

        context 'when user authenticated' do
          before do
            sign_in(user)
          end

          it_behaves_like 'enforces step-up authentication (request spec)'
        end

        context 'when user unauthenticated' do
          it_behaves_like 'does not enforce step-up authentication'
        end
      end
    end
  end

  describe 'GET #details' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group) }
    let_it_be(:user) { create(:user, developer_of: group) }
    let_it_be(:event) { create(:event, project: project) }

    before do
      sign_in(user)
    end

    subject(:get_details) { get details_group_path(group, format: :atom) }

    it 'renders the group activity atom feed with the correct events', :aggregate_failures do
      get_details

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type).to eq('application/atom+xml')
      expect(response.body).to include("#{group.name} activity")
      expect(response.body.scan('<entry>').size).to eq(1)
      expect(response.body).to include(":#{event.id}</id>")
    end
  end

  describe 'GET #new' do
    context 'step-up authentication enforcement' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:user) { create(:user, owner_of: group) }
      let(:expected_success_status) { :ok }

      subject(:make_request) { get new_group_path }

      before do
        sign_in(user)
      end

      it_behaves_like 'does not enforce step-up authentication'
    end
  end

  describe 'POST #create' do
    context 'step-up authentication enforcement' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:user) { create(:user, owner_of: group) }
      let(:expected_success_status) { :found }

      subject(:make_request) do
        post groups_path, params: { group: { name: 'New Group', path: 'new-group' } }
      end

      before do
        sign_in(user)
      end

      it_behaves_like 'does not enforce step-up authentication'
    end
  end

  describe 'GET #edit' do
    let_it_be_with_reload(:group) { create(:group, :public) }
    let_it_be(:owner) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let(:url) { edit_group_path(group) }

    before_all do
      group.add_owner(owner)
      group.add_maintainer(maintainer)
    end

    context 'when the group is archived' do
      before do
        group.namespace_settings.update!(archived: true)
      end

      context 'when user is owner' do
        before do
          login_as(owner)
        end

        it 'allows access to edit page' do
          get url

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when user is maintainer' do
        before do
          login_as(maintainer)
        end

        it 'returns a 404' do
          get url

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when the group is unarchived' do
      before do
        group.namespace_settings.update!(archived: false)
      end

      context 'when user is owner' do
        before do
          login_as(owner)
        end

        it 'allows access to edit page' do
          get url

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when user is maintainer' do
        before do
          login_as(maintainer)
        end

        it 'returns a 404' do
          get url

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'step-up authentication enforcement' do
      let_it_be_with_reload(:group) { create(:group) }

      subject(:make_request) { get edit_group_path(group) }

      before do
        sign_in(user)
      end

      context 'when user is owner' do
        let_it_be_with_reload(:user) { create(:user, owner_of: group) }

        let(:expected_success_status) { :ok }

        it_behaves_like 'does not enforce step-up authentication'
      end

      context 'when user is maintainer' do
        let_it_be_with_reload(:user) { create(:user, maintainer_of: group) }

        let(:expected_success_status) { :not_found }

        it_behaves_like 'does not enforce step-up authentication'
      end
    end
  end

  describe 'GET #activity' do
    context 'step-up authentication enforcement' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:user) { create(:user, owner_of: group) }
      let(:expected_success_status) { :ok }

      subject(:make_request) { get activity_group_path(group) }

      before do
        sign_in(user)
      end

      it_behaves_like 'enforces step-up authentication (request spec)'
    end

    context 'as JSON' do
      let_it_be(:group, freeze: false) { create(:group, :public) }
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:user) { create(:user, developer_of: group) }

      subject(:get_activity) { get activity_group_path(group), as: :json }

      before do
        sign_in(user)
      end

      it 'includes events from all projects in the group and its subgroups',
        :sidekiq_might_not_need_inline, :aggregate_failures do
        2.times do
          group_project = create(:project, group: group)
          create(:event, project: group_project)
        end
        subgroup = create(:group, parent: group, organization: group.organization)
        create(:event, project: create(:project, group: subgroup))

        get_activity

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['count']).to eq(3)
      end

      context 'with the event filter set to all' do
        before do
          cookies[:event_filter] = EventFilter::ALL
        end

        it 'includes transferred group events when group events are unavailable', :aggregate_failures do
          create(:event, :transferred, project: nil, group: group, target: group, target_type: 'Group', author: user)

          get_activity

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['count']).to eq(1)
        end

        it 'includes subgroup group-transfer events in the parent group activity', :aggregate_failures do
          subgroup = create(:group, :public, parent: group, organization: group.organization)
          create(:event, :transferred, project: nil, group: group, target: group, target_type: 'Group', author: user)
          create(:event, :transferred, project: nil, group: subgroup, target: subgroup, target_type: 'Group',
            author: user)

          get_activity

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['count']).to eq(2)
        end

        it 'includes project-transfer events in the group activity', :aggregate_failures do
          create(:event, :transferred, project: project, target: project, target_type: 'Project', author: user)

          get_activity

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['count']).to eq(1)
        end
      end
    end

    context 'when the user has no permission to see an event' do
      let_it_be(:group, freeze: false) { create(:group, :public) }
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:restricted_project) do
        create(:project, :public, issues_access_level: ProjectFeature::PRIVATE, group: group)
      end

      let_it_be(:user) { create(:user, guest_of: group) }

      before do
        create(:event, project: project)
        create(:event, :created, project: restricted_project, target: create(:issue))

        sign_in(user)
      end

      it 'filters out the invisible event', :aggregate_failures do
        get activity_group_path(group), as: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['count']).to eq(1)
      end
    end
  end

  describe 'GET #issues' do
    context 'step-up authentication enforcement' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:user) { create(:user, owner_of: group) }

      let(:expected_success_status) { :redirect }

      subject(:make_request) { get issues_group_path(group) }

      before do
        sign_in(user)
      end

      it_behaves_like 'enforces step-up authentication (request spec)'
    end
  end

  describe 'GET #merge_requests' do
    context 'step-up authentication enforcement' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:user) { create(:user, owner_of: group) }
      let(:expected_success_status) { :ok }

      subject(:make_request) { get merge_requests_group_path(group) }

      before do
        sign_in(user)
      end

      it_behaves_like 'enforces step-up authentication (request spec)'
    end
  end

  describe 'PATCH #update' do
    context 'step-up authentication enforcement' do
      let_it_be_with_reload(:group) { create(:group) }

      subject(:make_request) { patch group_path(group), params: { group: { name: 'Updated Name' } } }

      before do
        sign_in(user)
      end

      context 'when user is owner' do
        let_it_be_with_reload(:user) { create(:user, owner_of: group) }

        let(:expected_success_status) { :found }

        it_behaves_like 'does not enforce step-up authentication'
      end

      context 'when user is maintainer' do
        let_it_be_with_reload(:user) { create(:user, maintainer_of: group) }

        let(:expected_success_status) { :not_found }

        it 'responds with 404 before step-up authentication is triggered because user is not authorized' do
          make_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    include Namespaces::DeletableHelper

    context 'step-up authentication enforcement' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:user) { create(:user, owner_of: group) }
      let(:expected_success_status) { :found }

      subject(:make_request) { delete group_path(group) }

      before do
        sign_in(user)
      end

      it_behaves_like 'enforces step-up authentication (request spec)'
    end

    context 'deletion behaviour' do
      let_it_be_with_reload(:group) { create(:group, :public) }
      let_it_be(:owner) { create(:user, owner_of: group) }

      let(:format) { :html }
      let(:params) { {} }

      subject(:destroy_group) { delete group_path(group), params: params, as: format }

      context 'when the authenticated user can admin the group' do
        before do
          sign_in(owner)
        end

        context 'when the deletion is scheduled successfully' do
          it 'marks the group for delayed deletion and does not enqueue an immediate deletion', :aggregate_failures do
            Sidekiq::Testing.fake! do
              expect { destroy_group }
                .to change { group.reload.self_deletion_scheduled? }.from(false).to(true)
                .and not_change { GroupDestroyWorker.jobs.size }
            end
          end

          context 'for an HTML request' do
            it 'redirects to the groups dashboard' do
              destroy_group

              expect(response).to redirect_to(dashboard_groups_path)
            end
          end

          context 'for a JSON request', :freeze_time do
            let(:format) { :json }

            it 'returns a confirmation message' do
              destroy_group

              expect(json_response['message']).to eq(
                "'#{group.reload.name}' has been scheduled for deletion and will be deleted on " \
                  "#{permanent_deletion_date_formatted(group)}.")
            end
          end
        end

        context 'when the deletion fails' do
          before do
            allow_next_instance_of(::Groups::MarkForDeletionService) do |service|
              allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'error'))
            end
          end

          it 'does not mark the group for deletion' do
            expect { destroy_group }.not_to change { group.reload.self_deletion_scheduled? }.from(false)
          end

          context 'for an HTML request' do
            it 'redirects to the group edit page with an alert', :aggregate_failures do
              destroy_group

              expect(response).to redirect_to(edit_group_path(group))
              expect(flash[:alert]).to include('error')
            end
          end

          context 'for a JSON request' do
            let(:format) { :json }

            it 'returns the error message' do
              destroy_group

              expect(json_response['message']).to eq('error')
            end
          end
        end

        context 'when the group is already marked for deletion' do
          before do
            group.schedule_deletion!(transition_user: owner)
            create(:group_deletion_schedule, group: group, marked_for_deletion_on: Date.current)
          end

          context 'when the permanently_remove param is set' do
            let(:params) { { permanently_remove: true } }

            context 'for an HTML request' do
              it 'deletes the group immediately and redirects to the groups dashboard', :aggregate_failures do
                expect(GroupDestroyWorker).to receive(:perform_async)

                destroy_group

                expect(response).to redirect_to(dashboard_groups_path)
                expect(flash[:toast]).to include("#{group.name} is being deleted.")
              end
            end

            context 'for a JSON request' do
              let(:format) { :json }

              it 'deletes the group immediately and returns a confirmation message', :aggregate_failures do
                expect(GroupDestroyWorker).to receive(:perform_async)

                destroy_group

                expect(json_response['message']).to eq("#{group.name} is being deleted.")
              end
            end
          end
        end

        context 'when a group ancestor is already marked for deletion' do
          let_it_be(:nested_group) { create(:group, :nested, parent: group) }

          before do
            create(:group_deletion_schedule, group: group, marked_for_deletion_on: Date.current)
          end

          subject(:destroy_group) { delete group_path(nested_group), params: params, as: format }

          it 'redirects to the edit page with an alert', :aggregate_failures do
            destroy_group

            expect(response).to have_gitlab_http_status(:found)
            expect(flash[:alert]).to eq('Group ancestor has already been marked for deletion')
          end
        end
      end

      context 'when the authenticated user cannot admin the group' do
        before do
          sign_in(create(:user))
        end

        it 'returns 404' do
          destroy_group

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'PUT #transfer' do
    context 'step-up authentication enforcement' do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:user) { create(:user, owner_of: group) }
      let_it_be(:parent_group, freeze: true) { create(:group) }
      let(:expected_success_status) { :found }

      subject(:make_request) do
        put transfer_group_path(group), params: { new_parent_group_id: parent_group.id }
      end

      before do
        stub_feature_flags(groups_and_projects_async_transfer: false)
        sign_in(user)
        parent_group.add_owner(user)
      end

      it_behaves_like 'enforces step-up authentication (request spec)'
    end

    context 'when groups_and_projects_async_transfer feature flag is enabled' do
      let_it_be(:user) { create(:user) }
      let_it_be_with_reload(:group) { create(:group, :public) }
      let_it_be(:new_parent_group) { create(:group, :public) }

      before_all do
        group.add_owner(user)
        new_parent_group.add_owner(user)
      end

      before do
        sign_in(user)
      end

      it 'enqueues the async transfer worker' do
        expect(Namespaces::Groups::TransferWorker).to receive(:perform_async).with(
          group.id,
          new_parent_group.id,
          user.id
        )

        put transfer_group_path(group), params: { new_parent_group_id: new_parent_group.id }

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(group_path(group))
      end

      it 'transitions the group to transfer_scheduled and stores metadata' do
        put transfer_group_path(group), params: { new_parent_group_id: new_parent_group.id }

        group.reload
        expect(group.state).to eq('transfer_scheduled')
        expect(group.state_metadata['transfer_target_parent_id']).to eq(new_parent_group.id)
      end

      context 'when the state transition fails' do
        before do
          group.update_column(:state, Group.states[:creation_in_progress])
        end

        it 'does not enqueue the worker and redirects with an error' do
          expect(Namespaces::Groups::TransferWorker).not_to receive(:perform_async)

          put transfer_group_path(group), params: { new_parent_group_id: new_parent_group.id }

          expect(response).to redirect_to(edit_group_path(group))
          expect(flash[:alert]).to eq('Unable to initiate transfer. The group may already have a transfer in progress.')
        end
      end
    end

    context 'when groups_and_projects_async_transfer feature flag is disabled' do
      let_it_be(:user) { create(:user) }
      let_it_be_with_reload(:group) { create(:group, :public) }
      let_it_be(:new_parent_group) { create(:group, :public) }

      before_all do
        group.add_owner(user)
        new_parent_group.add_owner(user)
      end

      before do
        stub_feature_flags(groups_and_projects_async_transfer: false)
        sign_in(user)
      end

      it 'transfers the group synchronously' do
        expect(Namespaces::Groups::TransferWorker).not_to receive(:perform_async)

        put transfer_group_path(group), params: { new_parent_group_id: new_parent_group.id }

        expect(response).to have_gitlab_http_status(:found)
        expect(flash[:notice]).to eq("Group '#{group.name}' was successfully transferred.")
        expect(group.reload.parent).to eq(new_parent_group)
      end
    end
  end

  describe 'POST #export' do
    context 'step-up authentication enforcement', :clean_gitlab_redis_rate_limiting do
      let_it_be_with_reload(:group) { create(:group) }
      let_it_be_with_reload(:user) { create(:user, owner_of: group) }
      let(:expected_success_status) { :found }

      subject(:make_request) { post export_group_path(group) }

      before do
        sign_in(user)
      end

      it_behaves_like 'enforces step-up authentication (request spec)'
    end
  end
end
