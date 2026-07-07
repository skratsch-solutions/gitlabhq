# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GranularTokenAuthorization, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private, group: group, developers: user) }

  let(:harness_class) do
    Class.new do
      include GranularTokenAuthorization

      attr_accessor :project, :group
      attr_reader :rendered_404

      def render_404
        @rendered_404 = true
      end
    end
  end

  let(:harness_project) { project }
  let(:harness_group) { nil }
  let(:harness) do
    harness_class.new.tap do |h|
      h.project = harness_project
      h.group = harness_group
    end
  end

  let(:request_format) { :archive }
  let(:permission) { nil }
  let(:token) { nil }

  subject(:authorize) { harness.authorize_granular_token!(request_format, permission: permission) }

  # Mirror what the auth finders record on the request.
  before do
    ::Current.token_info = token && { token_type: 'PersonalAccessToken', token_id: token.id }
  end

  def granular_pat(permissions:, boundary: project)
    create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(boundary), permissions: permissions)
  end

  context 'when there is no token (session/cookie or feed token)' do
    let(:token) { nil }

    it 'does not deny the request' do
      authorize

      expect(harness.rendered_404).to be_nil
    end
  end

  context 'when the format is not enforced' do
    let(:request_format) { :graphql_api }
    let(:token) { create(:granular_pat, user: user) }

    it 'does not enforce' do
      authorize

      expect(harness.rendered_404).to be_nil
    end
  end

  context 'when authenticated with a granular personal access token' do
    context 'with the default permission for the format' do
      context 'with the format default' do
        let(:token) { granular_pat(permissions: :download_code) }

        it 'does not deny the request' do
          authorize

          expect(harness.rendered_404).to be_nil
        end
      end

      context 'without the format default' do
        let(:token) { granular_pat(permissions: :read_code) }

        it 'renders 404' do
          authorize

          expect(harness.rendered_404).to be(true)
        end
      end
    end

    context 'with an explicit permission overriding the default' do
      let(:request_format) { :rss }
      let(:permission) { :read_release }

      context 'with the explicit permission' do
        let(:token) { granular_pat(permissions: :read_release) }

        it 'does not deny the request' do
          authorize

          expect(harness.rendered_404).to be_nil
        end
      end

      context 'with only the format default' do
        let(:token) { granular_pat(permissions: :read_work_item) }

        it 'renders 404' do
          authorize

          expect(harness.rendered_404).to be(true)
        end
      end
    end

    context 'when scoped to a different project' do
      let_it_be(:other_project) { create(:project, :private, developers: user) }

      let(:token) { granular_pat(permissions: :download_code, boundary: other_project) }

      it 'renders 404' do
        authorize

        expect(harness.rendered_404).to be(true)
      end
    end

    context 'on a user boundary (no project or group in the request)' do
      let(:request_format) { :rss }
      let(:harness_project) { nil }

      context 'with a user-scoped token carrying the format default' do
        let(:token) { granular_pat(permissions: :read_work_item, boundary: ::Authz::GranularScope::Access::USER) }

        it 'does not deny the request' do
          authorize

          expect(harness.rendered_404).to be_nil
        end
      end

      context 'with a user-scoped token missing the permission' do
        let(:token) { granular_pat(permissions: :read_release, boundary: ::Authz::GranularScope::Access::USER) }

        it 'renders 404' do
          authorize

          expect(harness.rendered_404).to be(true)
        end
      end
    end
  end

  context 'when authenticated with a legacy personal access token' do
    let(:token) { create(:personal_access_token, user: user, scopes: %w[api]) }

    it 'does not deny the request when the namespace does not enforce granular tokens' do
      authorize

      expect(harness.rendered_404).to be_nil
    end

    context 'when the namespace enforces granular tokens' do
      before do
        group.namespace_settings.update!(
          enforce_granular_tokens: true,
          granular_tokens_enforced_after: Date.current
        )
      end

      it 'renders 404' do
        authorize

        expect(harness.rendered_404).to be(true)
      end
    end
  end
end
