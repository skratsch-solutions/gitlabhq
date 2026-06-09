# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::GrpcClient, feature_category: :system_access do
  subject(:client) { described_class.new }

  let(:iam_service_address) { 'localhost:5004' }
  let(:iam_secret) { 'test-secret-token' }

  let(:stub_double) do
    instance_double(::Auth::Auth::Stub)
  end

  before do
    allow(Authn::IamAuthService).to receive_messages(
      grpc_address: iam_service_address,
      secret: iam_secret
    )

    allow(::Auth::Auth::Stub).to receive(:new).and_return(stub_double)
  end

  describe '#health' do
    subject(:do_request) { client.health(request) }

    let(:request) { instance_double(::Auth::HealthRequest) }
    let(:response) { instance_double(::Auth::HealthResponse) }

    it 'returns health status' do
      expect(stub_double).to receive(:health).with(
        request,
        metadata: a_hash_including(
          "gitlab-iam-auth-token" => iam_secret
        )
      ).and_return(response)

      expect(do_request).to eq(response)
    end

    it 'raises RequestError on misconfiguration' do
      config_error = Authn::IamAuthService::ConfigurationError.new("test error message")

      expect(stub_double).to receive(:health).with(
        request,
        metadata: a_hash_including(
          "gitlab-iam-auth-token" => iam_secret
        )
      ).and_raise(config_error)

      expect { do_request }.to raise_error(described_class::RequestError, "test error message")
    end

    it 'rescues GRPC::BadStatus and raises a sanitized RequestError' do
      grpc_error = GRPC::Unavailable.new("test error message")

      expect(stub_double).to receive(:health).with(
        request,
        metadata: a_hash_including(
          "gitlab-iam-auth-token" => iam_secret
        )
      ).and_raise(grpc_error)

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(grpc_error)

      expect { do_request }.to raise_error(described_class::RequestError, 'Failed to connect to IAM service')
    end

    it 'rescues GRPC::Unauthenticated without leaking IAM service details' do
      grpc_error = GRPC::Unauthenticated.new("invalid token: internal details")

      expect(stub_double).to receive(:health).with(
        request,
        metadata: a_hash_including(
          "gitlab-iam-auth-token" => iam_secret
        )
      ).and_raise(grpc_error)

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(grpc_error)

      expect { do_request }.to raise_error(described_class::RequestError, 'Failed to connect to IAM service')
    end
  end

  describe 'channel credentials' do
    let(:request) { instance_double(::Auth::HealthRequest) }
    let(:response) { instance_double(::Auth::HealthResponse) }

    before do
      allow(stub_double).to receive(:health).and_return(response)
    end

    context 'with a plain host:port address' do
      let(:iam_service_address) { 'localhost:5004' }

      it 'builds the stub with insecure credentials and the address unchanged' do
        client.health(request)

        expect(::Auth::Auth::Stub).to have_received(:new).with(
          'localhost:5004',
          :this_channel_is_insecure,
          interceptors: [Labkit::Correlation::GRPC::ClientInterceptor.instance],
          timeout: described_class::TIMEOUT_SECONDS
        )
      end
    end

    context 'with a tls:// address' do
      let(:iam_service_address) { 'tls://iam.example.com:5004' }
      let(:tls_credentials) { instance_double(GRPC::Core::ChannelCredentials) }

      it 'builds the stub with TLS credentials and a stripped address' do
        allow(::Gitlab::X509::Certificate).to receive(:ca_certs_bundle).and_return('cert-data')
        allow(GRPC::Core::ChannelCredentials).to receive(:new).with('cert-data').and_return(tls_credentials)

        client.health(request)

        expect(::Auth::Auth::Stub).to have_received(:new).with(
          'iam.example.com:5004',
          tls_credentials,
          interceptors: [Labkit::Correlation::GRPC::ClientInterceptor.instance],
          timeout: described_class::TIMEOUT_SECONDS
        )
      end
    end

    context 'with a tcp:// address' do
      let(:iam_service_address) { 'tcp://iam.example.com:5004' }

      it 'builds the stub with insecure credentials and a stripped address' do
        client.health(request)

        expect(::Auth::Auth::Stub).to have_received(:new).with(
          'iam.example.com:5004',
          :this_channel_is_insecure,
          interceptors: [Labkit::Correlation::GRPC::ClientInterceptor.instance],
          timeout: described_class::TIMEOUT_SECONDS
        )
      end
    end

    context 'with a dns+tls:// address' do
      let(:iam_service_address) { 'dns+tls:///iam.example.com:5004' }
      let(:tls_credentials) { instance_double(GRPC::Core::ChannelCredentials) }

      it 'builds the stub with TLS credentials and rewrites the scheme to dns:' do
        allow(::Gitlab::X509::Certificate).to receive(:ca_certs_bundle).and_return('cert-data')
        allow(GRPC::Core::ChannelCredentials).to receive(:new).with('cert-data').and_return(tls_credentials)

        client.health(request)

        expect(::Auth::Auth::Stub).to have_received(:new).with(
          'dns:///iam.example.com:5004',
          tls_credentials,
          interceptors: [Labkit::Correlation::GRPC::ClientInterceptor.instance],
          timeout: described_class::TIMEOUT_SECONDS
        )
      end
    end

    context 'with an unparseable address' do
      let(:iam_service_address) { ':::invalid' }

      it 'falls back to insecure credentials' do
        client.health(request)

        expect(::Auth::Auth::Stub).to have_received(:new).with(
          ':::invalid',
          :this_channel_is_insecure,
          interceptors: [Labkit::Correlation::GRPC::ClientInterceptor.instance],
          timeout: described_class::TIMEOUT_SECONDS
        )
      end
    end
  end
end
