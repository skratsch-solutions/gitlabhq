# frozen_string_literal: true

module Integrations
  class Pumble < Integration
    include Base::ChatNotification
    include HasAvatar

    field :webhook,
      section: SECTION_TYPE_CONNECTION,
      help: -> { _('The Pumble webhook (for example, `https://api.pumble.com/workspaces/x/...`).') },
      required: true

    field :notify_only_broken_pipelines,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION,
      help: 'If selected, successful pipelines do not trigger a notification event.',
      description: -> { _('Send notifications for broken pipelines.') }

    field :branches_to_be_notified,
      type: :select,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('Integrations|Branches for which notifications are to be sent') },
      description: -> {
                     _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, ' \
                       'and `default_and_protected`. The default value is `default`.')
                   },
      choices: -> { branch_choices }

    def self.title
      'Pumble'
    end

    def self.description
      s_("PumbleIntegration|Send notifications about project events to Pumble.")
    end

    def self.to_param
      'pumble'
    end

    def self.help
      build_help_page_url(
        'user/project/integrations/pumble.md',
        s_("PumbleIntegration|Send notifications about project events to Pumble.")
      )
    end

    def default_channel_placeholder; end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push
        pipeline wiki_page]
    end

    private

    def notify(message, opts)
      header = { 'Content-Type' => 'application/json' }
      response = Gitlab::HTTP.post(webhook, headers: header, body: Gitlab::Json.dump({ text: message.summary }))

      response if response.success?
    end
  end
end
