# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- TODO include branch rules bounded context
module BranchRules
  module SquashOptions
    class BaseService < ::BranchRules::BaseService
      private

      def squash_option
        params[:squash_option]
      end

      def execute_on_all_protected_branches_rule
        ServiceResponse.error(
          message: 'All protected branch rules cannot configure squash options',
          payload: { errors: ['All protected branches not allowed'] },
          reason: :unprocessable_entity
        )
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
