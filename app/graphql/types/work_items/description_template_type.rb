# frozen_string_literal: true

module Types
  module WorkItems
    # rubocop: disable Graphql/AuthorizeTypes -- Authorization is done in the parent type
    class DescriptionTemplateType < BaseObject
      graphql_name 'WorkItemDescriptionTemplate'

      field :content, GraphQL::Types::String,
        description: 'Content of Description Template.', null: false, calls_gitaly: true
      field :name, GraphQL::Types::String,
        description: 'Name of Description Template.', null: false, calls_gitaly: true
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
