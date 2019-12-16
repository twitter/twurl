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
        elsif options.username
          load_client_for_username(options.username)
        elsif options.command == 'authorize' && options.app_only
          load_client_for_app_only_auth(options, options.consumer_key)
        elsif options.command == 'authorize'
          load_new_client_from_options(options)
        elsif options.command == 'request' && has_oauth_options?(options)
          load_new_client_from_oauth_options(options)
        elsif options.command == 'request' && options.app_only && options.consumer_key
          load_client_for_non_profile_app_only_auth(options)
        else
          load_default_client(options)
        end
      end

      def has_oauth_options?(options)
        (options.consumer_key && options.consumer_secret && options.access_token && options.token_secret) ? true : false
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

      def load_new_client_from_oauth_options(options)
        new(options.oauth_client_options.merge(
            'token' => options.access_token,
            'secret' => options.token_secret
          )
        )
      end

      def load_client_for_app_only_auth(options, consumer_key)
        if options.command == 'authorize'
          AppOnlyOAuthClient.new(options)
        else
          AppOnlyOAuthClient.new(
            options.oauth_client_options.merge(
              'bearer_token' => rcfile.bearer_tokens.to_hash[consumer_key]
            )
          )
        end
      end

      def load_client_for_non_profile_app_only_auth(options)
        AppOnlyOAuthClient.new(
          options.oauth_client_options.merge(
            'bearer_token' => rcfile.bearer_tokens.to_hash[options.consumer_key]
          )
        )
      end

      def load_default_client(options)
        return if options.command == 'oauth2_tokens'

        exception_message = "You must authorize first."
        app_only_exception_message = "To use --oauth2 option, you need to authorize (OAuth1.0a) and create at least one user profile (~/.twurlrc):\n\n" \
                                     "twurl authorize -c key -s secret\n" \
                                     "\nor, you can specify issued token's consumer_key directly:\n" \
                                     "(to see your issued tokens: 'twurl oauth2_tokens')\n\n" \
                                     "twurl --oauth2 -c key '/path/to/api'"

        raise Exception, "#{options.app_only ? app_only_exception_message : exception_message}" unless rcfile.default_profile
        if options.app_only
            raise Exception, "No available bearer token found for consumer_key:#{rcfile.default_profile_consumer_key}" \
              unless rcfile.has_bearer_token_for_consumer_key?(rcfile.default_profile_consumer_key)
            load_client_for_app_only_auth(options, rcfile.default_profile_consumer_key)
        else
          load_client_for_username_and_consumer_key(*rcfile.default_profile)
        end
      end
    end

    OAUTH_CLIENT_OPTIONS = %w[username consumer_key consumer_secret token secret]
    attr_reader *OAUTH_CLIENT_OPTIONS
    attr_reader :username, :password
    def initialize(options = {})
      @username        = options['username']
      @password        = options['password']
      @consumer_key    = options['consumer_key']
      @consumer_secret = options['consumer_secret']
      @token           = options['token']
      @secret          = options['secret']
      configure_http!
    end

    METHODS = {
        :post => Net::HTTP::Post,
        :get => Net::HTTP::Get,
        :put => Net::HTTP::Put,
        :delete => Net::HTTP::Delete,
        :options => Net::HTTP::Options,
        :head => Net::HTTP::Head,
        :copy => Net::HTTP::Copy
      }

    def build_request_from_options(options, &block)
      request_class = METHODS.fetch(options.request_method.to_sym)
      request = request_class.new(options.path, options.headers)

      if options.upload && options.upload['file'].count > 0
        boundary = "00Twurl" + rand(1000000000000000000).to_s + "lruwT99"
        multipart_body = []
        file_field = options.upload['filefield'] ? options.upload['filefield'] : 'media[]'

        options.data.each {|key, value|
          multipart_body << "--#{boundary}\r\n"
          multipart_body << "Content-Disposition: form-data; name=\"#{key}\"\r\n"
          multipart_body << "\r\n"
          multipart_body << value
          multipart_body << "\r\n"
        }

        options.upload['file'].each {|filename|
          multipart_body << "--#{boundary}\r\n"
          multipart_body << "Content-Disposition: form-data; name=\"#{file_field}\"; filename=\"#{File.basename(filename)}\"\r\n"
          multipart_body << "Content-Type: application/octet-stream\r\n"
          multipart_body << "Content-Transfer-Encoding: base64\r\n" if options.upload['base64']
          multipart_body << "\r\n"

          if options.upload['base64']
            enc = Base64.encode64(File.binread(filename))
            multipart_body << enc
          else
            multipart_body << File.binread(filename)
          end
        }

        multipart_body << "\r\n--#{boundary}--\r\n"

        request.body = multipart_body.join
        request.content_type = "multipart/form-data, boundary=\"#{boundary}\""
      elsif request.content_type && options.data
        request.body = options.data.keys.first
      elsif options.data
        request.content_type = "application/x-www-form-urlencoded"
        if options.data.length == 1 && options.data.values.first == nil
          request.body = options.data.keys.first
        else
          request.body = options.data.map do |key, value|
            "#{key}=#{CGI.escape value}"
          end.join("&")
        end
      end
      request
    end

    def perform_request_from_options(options, &block)
      request = build_request_from_options(options)
      request.oauth!(consumer.http, consumer, access_token)
      request['user-agent'] = user_agent
      consumer.http.request(request, &block)
    end

    def user_agent
      "twurl version: #{Version} " \
      "platform: #{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_PLATFORM})"
    end

    def exchange_credentials_for_access_token
      response = begin
        consumer.token_request(:post, consumer.access_token_path, nil, {}, client_auth_parameters)
      rescue OAuth::Unauthorized
        perform_pin_authorize_workflow
      end
      @token   = response[:oauth_token]
      @secret  = response[:oauth_token_secret]
    end

    def client_auth_parameters
      {'x_auth_username' => username, 'x_auth_password' => password, 'x_auth_mode' => 'client_auth'}
    end

    def perform_pin_authorize_workflow
      @request_token = consumer.get_request_token
      CLI.puts("Go to #{generate_authorize_url} and paste in the supplied PIN")
      pin = STDIN.gets
      access_token = @request_token.get_access_token(:oauth_verifier => pin.chomp)
      {:oauth_token => access_token.token, :oauth_token_secret => access_token.secret}
    end

    def generate_authorize_url
      request = consumer.create_signed_request(:get, consumer.authorize_path, @request_token, pin_auth_parameters)
      params = request['Authorization'].sub(/^OAuth\s+/, '').split(/,\s+/).map { |p|
        k, v = p.split('=')
        v =~ /"(.*?)"/
        "#{k}=#{CGI::escape($1)}"
      }.join('&')
      "#{Twurl.options.base_url}#{request.path}?#{params}"
    end

    def pin_auth_parameters
      {'oauth_callback' => 'oob'}
    end

    def fetch_verify_credentials
      access_token.get('/1.1/account/verify_credentials.json?include_entities=false&skip_status=true')
    end

    def authorized?
      oauth_response = fetch_verify_credentials
      oauth_response.class == Net::HTTPOK
    end

    def needs_to_authorize?
      token.nil? || secret.nil?
    end

    def save
      verify_has_username
      self.class.rcfile << self
    end

    def verify_has_username
      if username.nil? || username == ''
        oauth_response = fetch_verify_credentials
        oauth_response.body =~ /"screen_name"\s*:\s*"(.*?)"/
        @username = $1
      end
    end

    def to_hash
      OAUTH_CLIENT_OPTIONS.inject({}) do |hash, attribute|
        if value = send(attribute)
          hash[attribute] = value
        end
        hash
      end
    end

    def configure_http!
      consumer.http.set_debug_output(Twurl.options.debug_output_io) if Twurl.options.trace
      consumer.http.read_timeout = consumer.http.open_timeout = Twurl.options.timeout || 60
      consumer.http.open_timeout = Twurl.options.connection_timeout if Twurl.options.connection_timeout
      # Only override if Net::HTTP support max_retries (since Ruby >= 2.5)
      consumer.http.max_retries = 0 if consumer.http.respond_to?(:max_retries=)
      if Twurl.options.ssl?
        consumer.http.use_ssl     = true
        consumer.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end

    def consumer
      @consumer ||=
        OAuth::Consumer.new(
          consumer_key,
          consumer_secret,
          :site => Twurl.options.base_url,
          :proxy => Twurl.options.proxy
        )
    end

    def access_token
      @access_token ||= OAuth::AccessToken.new(consumer, token, secret)
    end
  end
end
