# frozen_string_literal: true

RSpec.shared_examples 'RequestPayloadLogger information appended' do
  it 'logs custom information in the payload' do
    expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
      method.call(payload)

      expect(payload[:remote_ip]).to be_present
      expect(payload[:username]).to eq(user.username)
      expect(payload[:user_id]).to be_present
      expect(payload[:user_is_bot]).to eq(user.bot?)
      expect(payload[:ua]).to be_present
    end

    subject
  end

  context 'when the request carries a Bearer token with the mcp scope' do
    let(:oauth_app) { create(:oauth_application, scopes: 'api mcp') }
    let(:mcp_token) { create(:oauth_access_token, application: oauth_app, scopes: 'api mcp') }

    before do
      request.headers['Authorization'] = "Bearer #{mcp_token.plaintext_token}"
    end

    it 'appends OAuth fields and sets is_mcp_request to true' do
      expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
        method.call(payload)

        expect(payload[:oauth_application_id]).to eq(oauth_app.id)
        expect(payload[:oauth_application_name]).to eq(oauth_app.name)
        expect(payload[:oauth_scopes]).to eq('api mcp')
        expect(payload[:is_mcp_request]).to be(true)
      end

      subject
    end
  end

  context 'when the request carries a Bearer token without the mcp scope' do
    let(:oauth_app) { create(:oauth_application, scopes: 'api') }
    let(:non_mcp_token) { create(:oauth_access_token, application: oauth_app, scopes: 'api') }

    before do
      request.headers['Authorization'] = "Bearer #{non_mcp_token.plaintext_token}"
    end

    it 'sets is_mcp_request to false' do
      expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
        method.call(payload)

        expect(payload[:is_mcp_request]).to be(false)
      end

      subject
    end
  end

  context 'when no Bearer token is present in the request' do
    it 'does not append OAuth fields to the payload' do
      expect(controller).to receive(:append_info_to_payload).and_wrap_original do |method, payload|
        method.call(payload)

        expect(payload).not_to have_key(:oauth_application_id)
        expect(payload).not_to have_key(:is_mcp_request)
      end

      subject
    end
  end
end
