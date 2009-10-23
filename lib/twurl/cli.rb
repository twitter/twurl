module Twurl
  class CLI
    SUPPORTED_COMMANDS     = %w(authorize)
    DEFAULT_COMMAND        = 'request'
    DEFAULT_REQUEST_METHOD = 'get'
    DEFAULT_HOST           = 'api.twitter.com'
    DEFAULT_PROTOCOL       = 'https'
    PATH_PATTERN           = /^\/\w+/

    class << self
      attr_reader :options

      def run(args)
        options = parse_options(args)
        dispatch(options)
      end

      def dispatch(options)
        client     = OAuthClient.load_from_options(options)
        controller = case options.command
                     when 'authorize'
                       AuthorizationController
                     when 'request'
                       RequestController
                     else
                       abort("Unsupported command: #{options.command}")
                     end
        controller.dispatch(client, options)
      end

      def parse_options(args)
        arguments = args.dup

        @options        = Options.new
        options.trace   = false
        options.data    = {}

        option_parser = OptionParser.new do |o|
          o.extend AvailableOptions

          o.banner = "Usage: twurl authorize -u username -p password --consumer-key HQsAGcVm5MQT3n6j7qVJw --consumer-secret asdfasd223sd2\n" +
                     "       twurl [options] /statuses/home_timeline.xml"

          o.section "Getting started:" do
            tutorial
          end

          o.section "Authorization options:" do
            username
            password
            consumer_key
            consumer_secret
            access_token
            token_secret
          end

          o.section "Common options:" do
            trace
            data
            host
            disable_ssl
            request_method
            help
          end
        end

        arguments                = option_parser.parse!(args)
        options.request_method ||= options.data.empty? ? DEFAULT_REQUEST_METHOD : 'post'
        options.protocol       ||= DEFAULT_PROTOCOL
        options.host           ||= DEFAULT_HOST
        options.command          = extract_command!(arguments)
        options.path             = extract_path!(arguments)
        options
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
              path = arguments.slice!(index)
              break
            end
          end
          path
        end
    end

    module AvailableOptions
      def options
        CLI.options
      end

      def section(heading, &block)
        separator ""
        separator heading

        instance_eval(&block)
      end

      def tutorial
        on('-T', '--tutorial', "Narrative overview of Twurl commands") do
          puts DATA.read
          exit
        end
      end

      def consumer_key
        on('-c', '--consumer-key [KEY]', "Your consumer key (required)") do |key|
          options.consumer_key = key
        end
      end

      def consumer_secret
        on('-s', '--consumer-secret [SECRET]', "Your consumer secret (required)") do |secret|
          options.consumer_secret = secret
        end
      end

      def access_token
        on('-a', '--access-token', 'Your access token') do |token|
          options.access_token = token
        end
      end

      def token_secret
        on('-S', '--token-secret', "Your token secret") do |secret|
          options.token_secret = secret
        end
      end

      def username
        on('-u', '--username [USERNAME]', 'Specify username to act on behalf of (required)') do |username|
          options.username = username
        end
      end

      def password
        on('-p', '--password [PASSWORD]', 'Specify username to act on behalf of (required)') do |password|
          options.password = password ? password : prompt_for_password
        end
      end

      def trace
        on('-t', '--[no-]trace', 'Trace request/response traffic (default: --no-trace)') do |trace|
          options.trace = trace
        end
      end

      def data
        on('-d', '--data [DATA]', 'Sends the specified data in a POST request to the HTTP server.') do |data|
          data.split('&').each do |pair|
            key, value = pair.split('=')
            options.data[key] = value
          end
        end
      end

      def host
        on('-H', '--host [HOST]', 'Specify host to make requests to (default: api.twitter.com)') do |host|
          options.host = host
        end
      end

      def disable_ssl
        on('-U', '--no-ssl', 'Disable SSL (default: SSL is enabled)') do |use_ssl|
          options.protocol = 'http'
        end
      end

      def request_method
        on('-X', '--request-method [METHOD]', 'Request method (default: GET)') do |request_method|
          options.request_method = request_method.downcase
        end
      end

      def help
        on_tail("-h", "--help", "Show this message") do
          puts self
          exit
        end
      end

      def prompt_for_password
        system "stty -echo"
        print "Password: "
        STDIN.gets.chomp
      ensure
        system "stty echo"
      end
    end

    class Options < OpenStruct
      def oauth_client_options
        OAuthClient::OAUTH_CLIENT_OPTIONS.inject({}) do |options, option|
          options[option] = send(option)
          options
        end
      end

      def base_url
        "#{protocol}://#{host}"
      end

      def ssl?
        protocol == 'https'
      end
    end
  end
end

__END__
First things first you need to authorize an account to use a consumer key and secret.

If you don't know your consumer key go here and register an OAuth
application: http://url

Example:

  twurl authorize -u noradio -p password   \
                  -c HQsAGcVm5MQT3n6j7qVJw \
                  -s TFbERBg8mAanMaAkhlyILQ16Stk2oEUzezr9pBSv1FU
