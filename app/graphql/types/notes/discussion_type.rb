# frozen_string_literal: true

module Types
  module Notes
    class DiscussionType < BaseObject
      graphql_name 'Discussion'

      authorize :read_note

      def self.authorization_scopes
        super + [:ai_workflows]
      end

      implements Types::Notes::BaseDiscussionInterface
      expose_permissions ::Types::PermissionTypes::Notes::Discussion

      field :noteable, Types::NoteableType, null: true,
        description: 'Object which the discussion belongs to.'
      field :notes, Types::Notes::NoteType.connection_type, null: false,
        description: 'All notes in the discussion.',
        max_page_size: 200

      def noteable
        noteable = object.noteable

        return unless Ability.allowed?(context[:current_user], :"read_#{noteable.to_ability_name}", noteable)

        # `noteable` is the `NoteableType` union. If its type is not one the union
        # can resolve, returning it raises mid-query (UnresolvedTypeError) and
        # surfaces to clients as an Internal server error -- failing the entire
        # request, even in a list like `User.events`. Return nil so the field is
        # simply absent for that one comment instead.
        return unless Types::NoteableType.resolvable?(noteable)

        noteable
      end
    end
  end
end
