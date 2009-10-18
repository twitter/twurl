module Twurl
  class OAuthClient
    class << self
      def load_from_rcfile
        new(RCFile.load)
      end
    end

    ATTRIBUTES = [:consumer_key, :consumer_secret, :token, :secret]
    attr_reader *ATTRIBUTES
    def initialize(options = {})
      @username        = options[:username]
      @password        = options[:password]
      @consumer_key    = options[:consumer_key]
      @consumer_secret = options[:consumer_secret]
      @token           = options[:token]
      @secret          = options[:secret]
    end

    def authorize(request_token, request_secret, options = {})
      request_token = OAuth::RequestToken.new(consumer, request_token, request_secret)
      @access_token = request_token.get_access_token(options)
      if authorized?
        @token  = @access_token.token
        @secret = @access_token.secret
      end
      @access_token
    end

    [:get, :post, :put, :delete, :options, :head, :copy].each do |request_method|
      class_eval(<<-EVAL, __FILE__, __LINE__)
        def #{request_method}(url, options = {})
          access_token.#{request_method}(url, options)
        end
      EVAL
    end

    def exchange_request_token_for_access_token
      system("open '#{request_token.authorize_url}'")
      print "Enter PIN: "
      pin = gets.chomp

      access_token = authorize(
        request_token.token,
        request_token.secret,
        :oauth_verifier => pin
      )
    end

    def authorized?
      oauth_response = access_token.get('/account/verify_credentials.json')
      oauth_response.class == Net::HTTPOK
    end

    def needs_to_authorize?
      token.nil? || secret.nil?
    end

    def save
      RCFile.write(self)
    end

    def request_token(options={})
      @request_token ||= consumer.get_request_token(options)
    end

    def authentication_request_token(options={})
      consumer.options[:authorize_path] = '/oauth/authenticate'
      request_token(options)
    end

    def to_hash
      ATTRIBUTES.inject({}) do |hash, attribute|
        if value = send(attribute)
          hash[attribute] = value
        end
        hash
      end
    end

    def to_rcfile
      to_hash.to_yaml
    end

    private
      def consumer
        @consumer ||= OAuth::Consumer.new(
          consumer_key,
          consumer_secret,
          :site => "http://api.twitter.com/"
        )
      end

      def access_token
        @access_token ||= OAuth::AccessToken.new(consumer, token, secret)
      end
  end
end