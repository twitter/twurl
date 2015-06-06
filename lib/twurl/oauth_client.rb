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
        elsif options.username || (options.command == 'authorize')
          load_new_client_from_options(options)
        else
          load_default_client
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

    def perform_request_from_options(options, &block)
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
            enc = Base64.encode64(File.read(filename))
            multipart_body << enc
          else
            multipart_body << File.read(filename)
          end
        }

        multipart_body << "\r\n--#{boundary}--\r\n"

        request.body = multipart_body.join
        request.content_type = "multipart/form-data, boundary=\"#{boundary}\""
      elsif request.content_type && options.data
        request.body = options.data.keys.first
      elsif options.data
        request.set_form_data(options.data)
      end

      request.oauth!(consumer.http, consumer, access_token)
      consumer.http.request(request, &block)
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
      pin = gets
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
