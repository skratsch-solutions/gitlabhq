# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/sessions/two_factor.html.haml', feature_category: :system_access do
  before do
    assign(:user, user)
  end

  context 'when user has otp active' do
    let(:user) { create(:user, :two_factor) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- 2FA traits populate via create callbacks; build_stubbed unusable

    it 'renders the Vue mount point instead of the otp form' do
      render

      expect(rendered).to have_selector('#js-2fa')
      expect(rendered).not_to have_field('user[otp_attempt]')
    end

    context 'when two_factor_vue is disabled' do
      before do
        stub_feature_flags(two_factor_vue: false)
      end

      it 'shows enter otp form' do
        render

        expect(rendered).to have_field('user[otp_attempt]')
      end
    end
  end

  context 'when user has WebAuthn active' do
    let(:user) { create(:user, :two_factor_via_webauthn) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- 2FA traits populate via create callbacks; build_stubbed unusable

    it 'renders the WebAuthn authentication vue root elements' do
      render

      expect(rendered).not_to have_selector('#js-authenticate-token-2fa')
      expect(rendered).to have_selector('#js-authentication-webauthn[data-remember-me="0"]')
    end
  end
end
