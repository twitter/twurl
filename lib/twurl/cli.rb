module Twurl
  class CLI
    SUPPORTED_COMMANDS     = %w(authorize accounts bearer_tokens alias set)
    DEFAULT_COMMAND        = 'request'
    PATH_PATTERN           = /^\/\w+/
    PROTOCOL_PATTERN       = /^\w+:\/\//
    README                 = File.dirname(__FILE__) + '/../../README.md'
    @output              ||= STDOUT

    class << self
      attr_accessor :output

      def run(args)
        begin
          options = parse_options(args)
        rescue Twurl::Exception => exception
          abort(exception.message)
        end
        dispatch(options)
      end

      def dispatch(options)
        client     = OAuthClient.load_from_options(options)
        controller = case options.command
                     when 'authorize'
                       AuthorizationController
                     when 'accounts'
                       AccountInformationController
                     when 'bearer_tokens'
                       AppOnlyTokenInformationController
                     when 'alias'
                       AliasesController
                     when 'set'
                       ConfigurationController
                     when 'request'
                       RequestController
                     end
        controller.dispatch(client, options)
      rescue Twurl::Exception => exception
        abort(exception.message)
      end

      def parse_options(args)
        Twurl.options         = Options.new
        Twurl.options.args    = args.dup
        Twurl.options.trace   = false
        Twurl.options.data    = {}
        Twurl.options.headers = {}
        Twurl.options.upload  = {}
        Twurl.options.upload['file'] = []

        option_parser = OptionParser.new do |o|
          o.extend AvailableOptions

          o.banner = <<-BANNER
Usage: twurl authorize --consumer-key key --consumer-secret secret
       twurl [options] /1.1/statuses/home_timeline.json

Supported Commands: #{SUPPORTED_COMMANDS.sort.join(', ')}
          BANNER

          o.section "Getting started:" do
            tutorial
          end

          o.section "Authorization options:" do
            username
            consumer_key
            consumer_secret
            access_token
            token_secret
          end

          o.section "Common options:" do
            trace
            data
            raw_data
            headers
            host
            quiet
            request_method
            help
            version
            proxy
            file
            filefield
            base64
            json_format
            timeout
            connection_timeout
            app_only
          end
        end

        begin
          arguments               = option_parser.parse!(args)
        rescue OptionParser::InvalidOption
          raise Exception "ERROR: undefined option"
        rescue Twurl::Exception
          raise
        rescue
          raise Exception "ERROR: invalid argument"
        end
        Twurl.options.command     = extract_command!(arguments)
        Twurl.options.path        = extract_path!(arguments)
        Twurl.options.subcommands = arguments
        
        if Twurl.options.command == DEFAULT_COMMAND and Twurl.options.path.nil? and Twurl.options.args.empty?
          CLI.puts option_parser
          raise Exception, "No path found"
        end

        Twurl.options
      end

      def output
        if Twurl.options && Twurl.options.output
          Twurl.options.output
        else
          @output
        end
      end

      def print(*args, &block)
        output.print(*args, &block)
        output.flush if output.respond_to?(:flush)
      end

      def puts(*args, &block)
        output.puts(*args, &block)
        output.flush if output.respond_to?(:flush)
      end

      def prompt_for(label)
        system "stty -echo"
        CLI.print "#{label}: "
        result = STDIN.gets.chomp
        CLI.puts
        result
      rescue Interrupt
        exit
      ensure
        system "stty echo"
      end

      private
        def extract_command!(arguments)
          if SUPPORTED_COMMANDS.include?(arguments.first)
            arguments.shift
          else
            DEFAULT_COMMAND
          end
        end

        def extract_path!(arguments)
          path = nil
          arguments.each_with_index do |argument, index|
            if argument[PATH_PATTERN]
              path_with_params = arguments.slice!(index)
              path, params = path_with_params.split("?", 2)
              if params
                path += "?" + escape_params(params)
              end
              break
            end
          end
          path
        end

        def escape_params(params)
          CGI::parse(params).map do |key, value|
            "#{CGI.escape(key)}=#{CGI.escape(value.first)}"
          end.join("&")
        end
    end

    module AvailableOptions
      def options
        Twurl.options
      end

      def section(heading, &block)
        separator ""
        separator heading

        instance_eval(&block)
      end

      def tutorial
        on('-T', '--tutorial', "Narrative overview of how to get started using Twurl") do
          CLI.puts IO.read(README)
          exit
        end
      end

      def consumer_key
        on('-c', '--consumer-key [key]', "Your consumer key (required)") do |key|
          options.consumer_key = key ? key : CLI.prompt_for('Consumer key')
        end
      end

      def consumer_secret
        on('-s', '--consumer-secret [secret]', "Your consumer secret (required)") do |secret|
          options.consumer_secret = secret ? secret : CLI.prompt_for('Consumer secret')
        end
      end

      def access_token
        on('-a', '--access-token [token]', 'Your access token') do |token|
          options.access_token = token
        end
      end

      def token_secret
        on('-S', '--token-secret [secret]', "Your token secret") do |secret|
          options.token_secret = secret
        end
      end

      def username
        on('-u', '--username [username]', 'Username of account to authorize (required)') do |username|
          options.username = username
        end
      end

      def trace
        on('-t', '--[no-]trace', 'Trace request/response traffic (default: --no-trace)') do |trace|
          options.trace = trace
        end
      end

      def data
        on('-d', '--data [data]', 'Sends the specified data in a POST request to the HTTP server.') do |data|
          if options.args.count { |item| /^content-type:\s+application\/json/i.match(item) } > 0
            options.json_data = true
            options.data = data
          else
            CGI.parse(data).each_pair do |key, value|
              options.data[key] = value.first
            end
          end
        end
      end

      def raw_data
        on('-r', '--raw-data [data]', 'Sends the specified data as it is in a POST request to the HTTP server.') do |data|
          if options.raw_data
            raise Exception, "ERROR: can't specify '-r' option more than once"
          elsif options.args.include?('-d') || options.args.include?('--data')
            raise Exception, "ERROR: can't use '-r' and '-d' options together"
          end
          options.raw_data = true
          options.data = data
        end
      end

      def headers
        on('-A', '--header [header]', 'Adds the specified header to the request to the HTTP server.') do |header|
          key, value = header.split(': ')
          options.headers[key] = value
        end
      end

      def host
        on('-H', '--host [host]', 'Specify host to make requests to (default: api.twitter.com)') do |host|
          if host[PROTOCOL_PATTERN]
            protocol, protocolless_host = host.split(PROTOCOL_PATTERN, 2)
            options.host = protocolless_host
          else
            options.host = host
          end
        end
      end

      def quiet
        on('-q', '--quiet', 'Suppress all output (default: output is printed to STDOUT)') do |quiet|
          options.output = StringIO.new
        end
      end

      def request_method
        on('-X', '--request-method [method]', 'Request method (default: GET)') do |request_method|
          options.request_method = request_method.downcase
        end
      end

      def help
        on_tail("-h", "--help", "Show this message") do
          CLI.puts self
          exit
        end
      end

      def version
        on_tail("-v", "--version", "Show version") do
          CLI.puts "twurl version: #{Version}\nplatform: #{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_PLATFORM})"
          exit
        end
      end

      def proxy
        on('-P', '--proxy [proxy]', 'Specify HTTP proxy to forward requests to (default: No proxy)') do |proxy|
          options.proxy = proxy
        end
      end

      def file
        on('-f', '--file [path_to_file]', 'Specify the path to the file to upload') do |file|
          if File.file?(file)
            options.upload['file'] << file
          else
            CLI.puts "ERROR: File not found"
            exit
          end
        end
      end

      def filefield
        on('-F', '--file-field [field_name]', 'Specify the POST parameter name for the file upload data (default: media)') do |filefield|
          options.upload['filefield'] = filefield
        end
      end

      def base64
        on('-b', '--base64', 'Encode the uploaded file as base64 (default: false)') do |base64|
          options.upload['base64'] = base64
        end
      end

      def json_format
        on('-j', '--json-pretty', 'Format response body to JSON pretty style') do |json_format|
          options.json_format = true
        end
      end

      def timeout
        on('--timeout [sec]', Integer, 'Number of seconds to wait for the request to be read (default: 60)') do |timeout|
          options.timeout = timeout
        end
      end

      def connection_timeout
        on('--connection-timeout [sec]', Integer, 'Number of seconds to wait for the connection to open (default: 60)') do |connection_timeout|
          options.connection_timeout = connection_timeout
        end
      end

      def app_only
        on('--bearer', "Use application-only authentication (Bearer Token)") do |app_only|
          options.app_only = true
        end
      end
    end
  end

  class Options < OpenStruct
    DEFAULT_REQUEST_METHOD = 'get'
    DEFAULT_HOST           = 'api.twitter.com'
    DEFAULT_PROTOCOL       = 'https'

    def oauth_client_options
      OAuthClient::OAUTH_CLIENT_OPTIONS.inject({}) do |options, option|
        options[option] = send(option)
        options
      end
    end

    def base_url
      "#{protocol}://#{host}"
    end

    def debug_output_io
      super || STDERR
    end

    def request_method
      super || (data.empty? ? DEFAULT_REQUEST_METHOD : 'post')
    end

    def protocol
      super || DEFAULT_PROTOCOL
    end

    def host
      super || DEFAULT_HOST
    end

    def proxy
      super || nil
    end
  end
end
