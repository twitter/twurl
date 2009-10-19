module Twurl
  class CLI
    SUPPORTED_COMMANDS     = %w(authorize)
    DEFAULT_COMMAND        = 'request'
    DEFAULT_REQUEST_METHOD = 'get'
    PATH_PATTERN           = /^\/\w+/

    class << self
      def run(args)
        options = parse_options(args)
        dispatch(options)
      end

      def dispatch(options)
        case options.command
        when 'authorize'
          AuthorizationController.dispatch(options)
        when 'request'
          RequestController.dispatch(client, options)
        else
          abort("Unsupported command: #{options.command}")
        end
      end

      def parse_options(args)
        arguments = args.dup

        options       = OpenStruct.new
        options.trace = false
        options.data  = {}

        option_parser = OptionParser.new do |o|
          o.extend Options
          o.options = options

          o.banner = "Usage: twurl authorize -u username -p password -c HQsAGcVm5MQT3n6j7qVJw -s asdfasd223sd2\n" +
                     "       twurl [options] /statuses/home_timeline.xml"

          o.section "Getting started:" do
            tutorial
          end

          o.section "Registration options:" do
            consumer_key
            consumer_secret
            access_token
            access_token_secret
          end

          o.section "Common options:" do
            trace
            data
            request_method
            help
          end
        end

        arguments                = option_parser.parse!(args)
        options.request_method ||= options.data.empty? ? DEFAULT_REQUEST_METHOD : 'post'
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

    module Options
      def self.extended(parser)
        class << parser
          attr_accessor :options
        end
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
        on('-c', '--consumer-key', "Your consumer key") do |key|
          options.consumer_key = key
        end
      end

      def consumer_secret
        on('-s', '--consumer-secret', "Your consumer secret") do |secret|
          options.consumer_secret = secret
        end
      end

      def access_token
        on('-a', '--access-token', 'Your access token') do |token|
          options.access_token = token
        end
      end

      def access_token_secret
        on('-S', '--access-token-secret', "Your access token secret") do |secret|
          options.access_token_secret = secret
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
