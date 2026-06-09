# frozen_string_literal: true

# This base service is reusable for any sub-feature within branch rules.
#
#
# A base service should be created for the subfeature which inherits from this
# class. Name the base service following this format
# `BranchRules::{SubFeature}::BaseService`.
#
# module BranchRules
#   module ExternalStatusChecks
#     class BaseService < ::BranchRules::BaseService
#     end
#   end
# end
#
#
# Additionally you may want to pass in additional objects by overriding the
# initializer
#
# module BranchRules
#   module SquashOptions
#     class BaseService < ::BranchRules::BaseService
#       def initialize(branch_rule, user: nil, params: {}, squash_option: nil)
#         @squash_option = squash_option
#         super(branch_rule, user: user, params: params)
#       end
#       attr_reader :squash_option
#     end
#   end
# end
#
#
# If 1 or more of the branch rules types are not valid for the subfeature
# return an error from the base service for that
# `execute_on_{branch_rule_type}`.
#
# module BranchRules
#   module ExternalStatusChecks
#     class BaseService < ::BranchRules::BaseService
#       private
#
#       def execute_on_all_branches_rule
#         ServiceResponse.error(
#           message: 'All branch rules cannot configure external status checks',
#           payload: { errors: ['All branch rules not allowed'] },
#           reason: :unprocessable_entity
#         )
#       end
#     end
#   end
# end
#
#
module BranchRules
  class BaseService
    include Gitlab::Allowable

    MISSING_METHOD_ERROR = Class.new(StandardError)

    attr_reader :branch_rule, :current_user, :params

    delegate :project, to: :branch_rule, allow_nil: true

    def initialize(branch_rule, user: nil, params: {})
      @branch_rule = branch_rule
      @current_user = user
      @params = ActionController::Parameters.new(**params).permit(*permitted_params).to_h
    end

    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || authorized?

      return execute_on_branch_rule if branch_rule.instance_of?(Projects::BranchRule)

      ServiceResponse.error(message: 'Unknown branch rule type.')
    end

    private

    def execute_on_branch_rule
      missing_method_error('execute_on_branch_rule')
    end

    def authorized?
      missing_method_error('authorized?')
    end

    def permitted_params
      []
    end

    def missing_method_error(method_name)
      raise MISSING_METHOD_ERROR, "Please define an `#{method_name}` method in #{self.class.name}"
    end
  end
end

BranchRules::BaseService.prepend_mod
