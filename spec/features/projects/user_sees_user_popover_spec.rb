# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sees user popover', :js, feature_category: :groups_and_projects do
  include Features::NotesHelpers

  let_it_be(:user) { create(:user, pronouns: 'they/them') }
  let_it_be(:project) { create(:project, :repository, creator: user) }

  let(:merge_request) do
    create(:merge_request, source_project: project, target_project: project)
  end

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  subject { page }

  describe 'hovering over a user link in a merge request' do
    let(:popover_selector) { '[data-testid="user-popover"]' }

    before do
      visit project_merge_request_path(project, merge_request)
    end

    it 'displays user popover' do
      hover_until_popover_appears('.detail-page-description .js-user-link')

      page.within(popover_selector) do
        expect(page).to have_content("#{user.name} (they/them)")
      end
    end

    it 'displays user popover in system note', :sidekiq_inline do
      add_note("/assign @#{user.username}")

      hover_until_popover_appears('.system-note-message .js-user-link')

      page.within(popover_selector) do
        expect(page).to have_content(user.name)
      end
    end

    # The popover launches from a delegated `mouseover` listener, so Capybara's
    # single synthetic hover can be dropped if the listener has not attached yet
    # or the page re-renders and shifts the link. Re-hovering absorbs that race.
    def hover_until_popover_appears(link_selector)
      wait_for('user popover to appear') do
        find(link_selector).hover
        has_css?(popover_selector, visible: :visible, wait: 0.5)
      end
    end
  end
end
