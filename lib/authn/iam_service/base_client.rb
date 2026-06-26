# frozen_string_literal: true

module Authn
  module IamService
    # Shared transport for IAM gRPC clients. Builds a stub for a given service
    # and selects channel credentials from the address scheme (tls:// vs plaintext).
    #
    # Subclasses own the service-specific address, stub class, timeout, metadata,
    # and error handling. This base holds only the transport that is identical
    # across IAM clients.
    class BaseClient
      InsecureChannelError = Class.new(StandardError)

      private

      def build_stub(stub_class, address, timeout:)
        stub_class.new(
          strip_scheme(address),
          channel_credentials(address),
          interceptors: [Labkit::Correlation::GRPC::ClientInterceptor.instance],
          timeout: timeout
        )
      end

      def channel_credentials(address)
        uri = URI(address)

        return GRPC::Core::ChannelCredentials.new(::Gitlab::X509::Certificate.ca_certs_bundle) if uri.scheme == 'tls'

        insecure_channel
      rescue URI::InvalidURIError
        insecure_channel
      end

      # A plaintext channel is only acceptable in development and test. Outside
      # those, refuse rather than silently talking to IAM without TLS.
      def insecure_channel
        unless Gitlab.dev_or_test_env?
          raise InsecureChannelError, 'Refusing to use an insecure IAM gRPC channel outside development and test'
        end

        :this_channel_is_insecure
      end

      def strip_scheme(address)
        address.sub(%r{^tcp://|^tls://}, '')
      end
    end
  end
end
