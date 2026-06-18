# frozen_string_literal: true

require 'webauthn/fake_client'

class FakeWebauthnDevice
  attr_reader :name

  def initialize(page, name, device = nil)
    @page = page
    @name = name
    @webauthn_device = device
  end

  def respond_to_webauthn_registration
    app_id = @page.evaluate_script('window.location.origin')
    wait_for_webauthn_options
    challenge = @page.evaluate_script('gon.webauthn.options.challenge')

    options = {
      challenge: challenge,
      extensions: { "credProps" => { "rk" => true } },
      user_verified: true
    }

    json_response = webauthn_device(app_id).create(**options).to_json # rubocop:disable Rails/SaveBang
    @page.execute_script <<~JS
      var result = #{json_response};
      result.getClientExtensionResults = () => (result['clientExtensionResults']);
      navigator.credentials.create = function(_) {
        return Promise.resolve(result);
      };
    JS
  end

  def respond_to_webauthn_authentication(passkey: nil)
    app_id = @page.evaluate_script('window.location.origin')
    wait_for_webauthn_options
    challenge = @page.evaluate_script('JSON.parse(gon.webauthn.options).challenge')

    options = {
      challenge: challenge,
      extensions: { "credProps" => { "rk" => true } },
      user_verified: true
    }

    begin
      json_response = webauthn_device(app_id).get(**options).to_json

    rescue RuntimeError
      # A runtime error is raised from fake webauthn if no credentials have been registered yet.
      # To be able to test non registered devices, credentials are created ad-hoc
      webauthn_device(app_id).create # rubocop:disable Rails/SaveBang
      json_response = webauthn_device(app_id).get(challenge: challenge).to_json
    end

    @page.execute_script <<~JS
      var result = #{json_response};
      result.getClientExtensionResults = () => (result['clientExtensionResults']);
      navigator.credentials.get = function(_) {
        return Promise.resolve(result);
      };
    JS

    if passkey
      @page.click_button(_('Try again'))
    else
      @page.click_button(_('Try again?'))
    end
  end

  def fake_webauthn_authentication
    @page.execute_script <<~JS
      const mockResponse = {
        type: 'public-key',
        id: '',
        rawId: '',
        response: { clientDataJSON: '', authenticatorData: '', signature: '', userHandle: '' },
        getClientExtensionResults: () => {},
      };
      window.gl.resolveWebauthn(mockResponse);
    JS
  end

  def add_credential(app_id, credential_id, credential_key)
    credentials = { URI.parse(app_id).host => { credential_id => { credential_key: credential_key, sign_count: 0 } } }
    webauthn_device(app_id).send(:authenticator).instance_variable_set(:@credentials, credentials)
  end

  private

  # The WebAuthn challenge page populates `gon.webauthn.options` asynchronously
  # once its JavaScript bundle has loaded. Reading the challenge before that
  # happens raises "Cannot read properties of undefined". Wait for the value to
  # be present before any `evaluate_script` call dereferences it.
  def wait_for_webauthn_options(max_wait_time: Capybara.default_max_wait_time)
    wait_until = ::Gitlab::Metrics::System.monotonic_time + max_wait_time
    loop do
      break if @page.evaluate_script('Boolean(window.gon && gon.webauthn && gon.webauthn.options)')

      raise 'Condition not met: gon.webauthn.options populated' if
        ::Gitlab::Metrics::System.monotonic_time > wait_until

      sleep(0.05)
    end
  end

  def webauthn_device(app_id)
    @webauthn_device ||= WebAuthn::FakeClient.new(app_id)
  end
end
