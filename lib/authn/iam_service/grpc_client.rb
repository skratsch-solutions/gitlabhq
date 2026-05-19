# frozen_string_literal: true

module Authn
  module IamService
    class GrpcClient
      RequestError = Class.new(StandardError)

      TIMEOUT_SECONDS = 5

      def health(request)
        call(:health, request)
      end

      private

      def call(method_name, request)
        options = { metadata: metadata }

        case method_name
        when :health then stub.health(request, **options)
        end
      rescue Authn::IamAuthService::ConfigurationError => e
        raise RequestError, e.message
      rescue GRPC::BadStatus => e
        Gitlab::ErrorTracking.track_exception(e)
        raise RequestError, 'Failed to connect to IAM service'
      end

      def stub
        # TODO: add mTLS support when IAM service exposes it
        address = Authn::IamAuthService.grpc_address
        ::Auth::Auth::Stub.new(
          strip_scheme(address),
          channel_credentials(address),
          interceptors: [Labkit::Correlation::GRPC::ClientInterceptor.instance],
          timeout: TIMEOUT_SECONDS
        )
      end

      def channel_credentials(address)
        uri = URI(address)

        if uri.scheme == 'tls' || uri.scheme == 'dns+tls'
          GRPC::Core::ChannelCredentials.new(::Gitlab::X509::Certificate.ca_certs_bundle)
        else
          :this_channel_is_insecure
        end
      rescue URI::InvalidURIError
        :this_channel_is_insecure
      end

      def strip_scheme(address)
        address.sub(%r{^tcp://|^tls://}, '').sub(%r{^dns\+tls:}, 'dns:')
      end

      def metadata
        { Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => Authn::IamAuthService.secret }
      end
    end
  end
end
