# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      module ParameterizedDefinition
        extend ActiveSupport::Concern

        attr_reader :parameters

        def initialize(*args, parameters: {}, **kwargs)
          super

          @parameters = parameters || {}
        end

        def instance_key(configuration)
          return super unless parameterized? && configuration[:parameters].present?

          parameters_postfix = parameters.keys.map { |p_key| instance_parameter(p_key, configuration) || '' }.join('_')

          unless /\A\w+\z/.match?(parameters_postfix)
            parameters_postfix = OpenSSL::Digest::SHA256.hexdigest(parameters_postfix)[0...5]
          end

          "#{super}_#{parameters_postfix}"
        end

        private

        def instance_parameter(param_identifier, configuration)
          parameters[param_identifier] && configuration.dig(:parameters, param_identifier)
        end

        def parameterized?
          parameters.present?
        end
      end
    end
  end
end
