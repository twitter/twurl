module Twurl
  class OAuthClient
    class << self
      def rcfile(reload = false)
        if reload || @rcfile.nil?
          @rcfile = RCFile.new
        end
        @rcfile
      end

      def load_from_options(options)
        if rcfile.has_oauth_profile_for_username_with_consumer_key?(options.username, options.consumer_key)
          load_client_for_username_and_consumer_key(options.username, options.consumer_key)
        else
          options.username ? load_new_client_from_options(options) : load_default_client
        end
      end

      def load_client_for_username_and_consumer_key(username, consumer_key)
        user_profiles = rcfile[username]
        if user_profiles && attributes = user_profiles[consumer_key]
          new(attributes)
        else
          raise Exception, "No profile for #{username}"
        end
      end

      def load_client_for_username(username)
        if user_profiles = rcfile[username]
          if user_profiles.values.size == 1
            new(user_profiles.values.first)
          else
            raise Exception, "There is more than one consumer key associated with #{username}. Please specify which consumer key you want as well."
          end
        else
          raise Exception, "No profile for #{username}"
        end
      end

      def load_new_client_from_options(options)
        new(options.oauth_client_options.merge('password' => options.password))
      end

      def load_default_client
        raise Exception, "You must authorize first" unless rcfile.default_profile
        load_client_for_username_and_consumer_key(*rcfile.default_profile)
      end
    end

    OAUTH_CLIENT_OPTIONS = %w[username consumer_key consumer_secret token secret]
    attr_reader *OAUTH_CLIENT_OPTIONS
    attr_reader :password
    def initialize(options = {})
      @username        = options['username']
      @password        = options['password']
      @consumer_key    = options['consumer_key']
      @consumer_secret = options['consumer_secret']
      @token           = options['token']
      @secret          = options['secret']
    end

    [:get, :post, :put, :delete, :options, :head, :copy].each do |request_method|
      class_eval(<<-EVAL, __FILE__, __LINE__)
        def #{request_method}(url, options = {})
          access_token.#{request_method}(url, options)
        end
      EVAL
    end

    def perform_request_from_options(options)
      send(options.request_method, options.path, options.data)
    end

    def exchange_credentials_for_access_token
      response = consumer.token_request(:post, consumer.access_token_path, nil, {}, client_auth_parameters)
      @token   = response[:oauth_token]
      @secret  = response[:oauth_token_secret]
    end

    def client_auth_parameters
      {:x_auth_username => username, :x_auth_password => password, :x_auth_mode => 'client_auth'}
    end

    def authorized?
      oauth_response = access_token.get('/1/account/verify_credentials.json')
      oauth_response.class == Net::HTTPOK
    end

    def needs_to_authorize?
      token.nil? || secret.nil?
    end

    def save
      self.class.rcfile << self
    end

    def to_hash
      OAUTH_CLIENT_OPTIONS.inject({}) do |hash, attribute|
        if value = send(attribute)
          hash[attribute] = value
        end
        hash
      end
    end

    def consumer
      @consumer ||=
      begin
        consumer = OAuth::Consumer.new(
          consumer_key,
          consumer_secret,
          :site => Twurl.options.base_url
        )
        consumer.http.set_debug_output(Twurl.options.debug_output_io) if Twurl.options.trace
        if Twurl.options.ssl?
          consumer.http.use_ssl     = true
          consumer.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        consumer
      end
    end

    def access_token
      @access_token ||= OAuth::AccessToken.new(consumer, token, secret)
    end
  end
end