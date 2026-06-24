# frozen_string_literal: true

module Onboarding
  class FeatureLibraryController < ApplicationController
    feature_category :onboarding
    urgency :low

    MAX_QUERY_LENGTH = 255

    before_action :check_feature_library_search_rate_limit!,
      only: :search,
      if: -> { Feature.enabled?(:feature_library_modal, current_user) }

    def search
      return not_found unless Feature.enabled?(:feature_library_modal, current_user)
      return render json: { ids: [] } unless valid_panel?

      ids = Onboarding::FeatureLibrary::FeatureMatchService.new(
        query: truncated_query,
        panel: search_params[:panel]
      ).execute

      render json: { ids: ids }
    end

    private

    def search_params
      params.permit(:query, :panel)
    end

    def valid_panel?
      Onboarding::FeatureLibrary::FeatureMatchService::VALID_PANELS.include?(search_params[:panel])
    end

    def truncated_query
      search_params[:query].to_s.first(MAX_QUERY_LENGTH)
    end

    def check_feature_library_search_rate_limit!
      check_rate_limit!(:feature_library_search, scope: current_user) do
        render json: { error: _('This endpoint has been requested too many times. Try again later.') },
          status: :too_many_requests
      end
    end
  end
end
