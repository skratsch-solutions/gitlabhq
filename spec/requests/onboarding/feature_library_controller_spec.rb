# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::FeatureLibraryController, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  describe 'GET /-/onboarding/feature_library/search' do
    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(feature_library_modal: false)
        sign_in(user)
      end

      it 'returns 404' do
        get onboarding_feature_library_search_path, params: { query: 'pr', panel: 'project' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the feature flag is enabled' do
      before do
        sign_in(user)
      end

      it 'returns 200 with a non-empty ids array for a valid request', :aggregate_failures do
        get onboarding_feature_library_search_path, params: { query: 'pr', panel: 'project' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['ids']).to be_an(Array).and include('project_merge_request_list')
      end

      context 'with an invalid panel' do
        it 'returns an empty ids array', :aggregate_failures do
          get onboarding_feature_library_search_path, params: { query: 'pr', panel: 'invalid' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['ids']).to eq([])
        end
      end

      context 'when the query parameter is missing' do
        it 'returns an empty ids array', :aggregate_failures do
          get onboarding_feature_library_search_path, params: { panel: 'project' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['ids']).to eq([])
        end
      end

      context 'when not authenticated' do
        before do
          sign_out(user)
        end

        it 'redirects to sign in' do
          get onboarding_feature_library_search_path, params: { query: 'pr', panel: 'project' }

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end
end
