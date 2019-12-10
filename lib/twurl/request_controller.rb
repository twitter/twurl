module Twurl
  class RequestController < AbstractCommandController
    NO_URI_MESSAGE = "No URI specified"
    READ_TIMEOUT_MESSAGE = 'A timeout occurred (Net::ReadTimeout). ' \
                           'Please try again or increase the value using --timeout option.'
    OPEN_TIMEOUT_MESSAGE = 'A timeout occurred (Net::OpenTimeout). ' \
                           'Please try again or increase the value using --connection-timeout option.'
    def dispatch
      if client.needs_to_authorize?
        raise Exception, "You need to authorize first."
      end
      options.path ||= OAuthClient.rcfile.alias_from_options(options)
      perform_request
    end

    def perform_request
      client.perform_request_from_options(options) { |response|
        response.read_body { |chunk| CLI.print chunk }
      }
    rescue URI::InvalidURIError
      CLI.puts NO_URI_MESSAGE
    rescue Net::ReadTimeout
      CLI.puts READ_TIMEOUT_MESSAGE
    rescue Net::OpenTimeout
      CLI.puts OPEN_TIMEOUT_MESSAGE
    end
  end
end
