# frozen_string_literal: true

module Types
  class NoteableType < BaseUnion
    graphql_name 'NoteableType'
    description 'Represents an object that supports notes.'

    possible_types Types::IssueType,
      Types::MergeRequestType,
      Types::SnippetType,
      Types::DesignManagement::DesignType,
      Types::AlertManagement::AlertType,
      Types::Wikis::WikiPageType

    # Delegate to NoteableInterface so the union and the interface share a single
    # source of truth for noteable type resolution. They previously duplicated this
    # mapping and drifted: noteables added to the interface (snippets, wiki pages,
    # alerts) were missing from the union, so resolving them through
    # `Discussion.noteable` raised and surfaced to clients as an Internal server error.
    def self.resolve_type(object, context)
      ::Types::Notes::NoteableInterface.resolve_type(object, context)
    end

    # Defense in depth against the union drifting out of sync again. `resolve_type`
    # raises for any noteable the interface does not map (e.g. a commit), and can
    # also return a type the EE interface knows about but that is not listed in
    # `possible_types` (e.g. a vulnerability). Both cases raise mid-query and
    # surface to clients as an Internal server error that fails the *whole* request
    # -- including list queries such as `User.events`, where a single comment on an
    # unmapped noteable would otherwise take down the entire page of results.
    #
    # Callers (see `Discussion#noteable`) use this to render the field as null for
    # an unresolvable noteable instead of failing the request. It never raises, so a
    # new or unexpected noteable type degrades gracefully rather than 500-ing.
    def self.resolvable?(object)
      possible_types.include?(resolve_type(object, {}))
    rescue StandardError
      false
    end
  end
end
