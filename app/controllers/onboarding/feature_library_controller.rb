# frozen_string_literal: true

module Onboarding
  class FeatureLibraryController < ApplicationController
    feature_category :onboarding
    urgency :low

    def search
      return not_found unless Feature.enabled?(:feature_library_modal, current_user)
      return render json: { ids: [] } unless valid_panel?

      ids = Onboarding::FeatureLibrary::FeatureMatchService.new(
        query: search_params[:query],
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
  end
end
