module Twurl
  class CLI
    SUPPORTED_COMMANDS = %w(authorize)
    PATH_PATTERN       = /^\/\w+/

    class << self
      def run(args)
        options = parse_options(args)
        p options
      end

      def parse_options(args)
        arguments = args.dup

        options       = OpenStruct.new
        options.trace = false

        option_parser = OptionParser.new do |_|
          _.banner = "Usage: twurl authorize -u username -p password -c HQsAGcVm5MQT3n6j7qVJw -s asdfasd223sd2\n" +
                     "       twurl [options] /statuses/home_timeline.xml"

          _.separator ""
          _.separator "Getting started:"

          _.on('-T', '--tutorial', "Narrative overview of Twurl commands") do
            puts DATA.read
            exit
          end

          _.separator ""
          _.separator "Registration options:"

          _.on('-c', '--consumer-key', "Your consumer key") do |key|
            options.consumer_key = key
          end

          _.on('-s', '--consumer-secret', "Your consumer secret") do |secret|
            options.consumer_secret = secret
          end

          _.on('-a', '--access-token', 'Your access token') do |token|
            options.access_token = token
          end

          _.on('-S', '--access-token-secret', "Your access token secret") do |secret|
            options.access_token_secret = secret
          end

          _.separator ""
          _.separator "Common options:"

          _.on('-t', '--trace', 'Trace request/response traffic') do
            options.trace = true
          end

          _.on('-X', '--request-method', 'Request method (default: GET)') do |request_method|
            options.request_method = request_method.downcase
          end

          _.on_tail("-h", "--help", "Show this message") do
            puts _
            exit
          end
        end

        arguments       = option_parser.parse!(args)
        options.command = extract_command!(arguments)
        options.path    = extract_path!(arguments)
        options
      end

      private
        def extract_command!(arguments)
          if SUPPORTED_COMMANDS.include?(arguments.first)
            arguments.shift
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

    run(ARGV)
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
