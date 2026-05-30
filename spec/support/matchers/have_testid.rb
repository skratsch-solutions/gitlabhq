# frozen_string_literal: true

require_relative '../helpers/capybara_node_helpers'

RSpec::Matchers.define :have_testid do |testid, text: nil|
  include CapybaraNodeHelpers

  match do |actual|
    capybara_node_from(actual).has_selector?("[data-testid='#{testid}']", text: text)
  end

  match_when_negated do |actual|
    capybara_node_from(actual).has_no_selector?("[data-testid='#{testid}']", text: text)
  end
end
