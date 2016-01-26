require 'base64'
require 'json'
require_relative 'oauth_client'

module Twurl
  class AppOnlyOAuthClient < Twurl::OAuthClient

    AUTHORIZATION_FAILED_MESSAGE = "Authorization failed. Check that your consumer key and secret are correct, "\
                                   "and that your token is allowed for Application-only authentication"
    def initialize(options = {})
      @username        = options['username'] #specified in rcfile (app-only)
      @consumer_key    = options['consumer_key']
      @consumer_secret = options['consumer_secret']
      @token           = options['token']
      configure_http!
    end

    def save
      Twurl::OAuthClient.rcfile << self
    end

    def exchange_credentials_for_access_token
      response = token_request
      if response.nil? || response[:access_token].nil?
        raise Exception, AUTHORIZATION_FAILED_MESSAGE
      end
      @token   = response[:access_token]
    end

    def perform_request_from_options(options, &block)
      request = build_request_from_options(options)
      request_headers.map do |header, value|
        request[header] = value
      end
      http_client.request(request, &block)
    end

    def needs_to_authorize?
      token.nil?
    end

    def oauth_consumer_options
      @consumer_options ||= super.merge({:access_token_path => '/oauth2/token'})
    end

    private
    def request_data
      {'grant_type' => 'client_credentials'}
    end

    def request_authorize_headers
      {'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8'}
        .merge(authorization_header)
    end

    def authorization_header
      bearer_token = Base64.strict_encode64("#{@consumer_key}:#{@consumer_secret}")
      {'Authorization' => "Basic #{bearer_token}"}
    end

    def request_headers
      {'Authorization' => "Bearer #{token}"}
    end

    def http_client
      uri = URI.parse(oauth_consumer_options[:site])
      http = if oauth_consumer_options[:proxy]
        proxy_uri = URI.parse(oauth_consumer_options[:proxy])
        Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port)
      else
        Net::HTTP.new(uri.host, uri.port)
      end
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http
    end

    def token_request
      request = Net::HTTP::Post.new(oauth_consumer_options[:access_token_path])
      request.body = request_data.map{|k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}"}.join("&")
      request_authorize_headers.map do |header, value|
        request[header] = value
      end
      JSON.parse(http_client.request(request).body,:symbolize_names => true)
    end
  end
end