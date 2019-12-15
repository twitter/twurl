require 'base64'
require_relative 'oauth_client'

module Twurl
  class AppOnlyOAuthClient < Twurl::OAuthClient

    AUTHORIZATION_FAILED_MESSAGE = "Authorization failed. Check that your consumer key and secret are correct."

    attr_reader :consumer_key, :consumer_secret, :bearer_token

    def initialize(options = {})
      @consumer_key    = options['consumer_key']
      @consumer_secret = options['consumer_secret']
      @bearer_token    = options['bearer_token']
    end

    def save
      self.class.rcfile.bearer_token(consumer_key, bearer_token)
    end

    def exchange_credentials_for_access_token
      response = fetch_oauth2_token
      if response.nil? || response[:access_token].nil?
        raise Exception, AUTHORIZATION_FAILED_MESSAGE
      end
      @bearer_token = response[:access_token]
    end

    def perform_request_from_options(options, &block)
      request = build_request_from_options(options)
      request['user-agent'] = user_agent
      request['authorization'] = "Bearer #{bearer_token}"

      http_client.request(request, &block)
    end

    def needs_to_authorize?
      bearer_token.nil?
    end

    def request_data
      {'grant_type' => 'client_credentials'}
    end

    def http_client
      uri = URI.parse(Twurl.options.base_url)
      http = if Twurl.options.proxy
        proxy_uri = URI.parse(Twurl.options.proxy)
        Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port)
      else
        Net::HTTP.new(uri.host, uri.port)
      end
      set_http_client_options(http)
    end

    def set_http_client_options(http)
      http.set_debug_output(Twurl.options.debug_output_io) if Twurl.options.trace
      http.read_timeout = http.open_timeout = Twurl.options.timeout || 60
      http.open_timeout = Twurl.options.connection_timeout if Twurl.options.connection_timeout
      # Only override if Net::HTTP support max_retries (since Ruby >= 2.5)
      http.max_retries = 0 if http.respond_to?(:max_retries=)
      if Twurl.options.ssl?
        http.use_ssl     = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http
    end

    def fetch_oauth2_token
      request = Net::HTTP::Post.new('/oauth2/token')
      request.body = URI.encode_www_form(request_data)
      request['user-agent'] = user_agent
      request['authorization'] = "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}"
      response = http_client.request(request).body
      JSON.parse(response,:symbolize_names => true)
    end
  end
end
