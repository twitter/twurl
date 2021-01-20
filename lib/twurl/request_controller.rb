module Twurl
  class RequestController < AbstractCommandController
    NO_URI_MESSAGE       = 'No URI specified'
    INVALID_URI_MESSAGE  = 'Invalid URI detected'
    READ_TIMEOUT_MESSAGE = 'A timeout occurred (Net::ReadTimeout). ' \
                           'Please try again or increase the value using --timeout option.'
    OPEN_TIMEOUT_MESSAGE = 'A timeout occurred (Net::OpenTimeout). ' \
                           'Please try again or increase the value using --connection-timeout option.'
    def dispatch
      if client.needs_to_authorize?
        raise Exception, "You need to authorize first."
      end
      options.path ||= OAuthClient.rcfile.alias_from_options(options)
      raise Exception, NO_URI_MESSAGE if options.path.empty?
      perform_request
    end

    def perform_request
      client.perform_request_from_options(options) { |response|
        response.read_body { |body|
          CLI.print options.json_format ? JsonFormatter.format(body) : body
        }
      }
    rescue URI::InvalidURIError
      raise Exception, INVALID_URI_MESSAGE
    rescue Net::ReadTimeout
      raise Exception, READ_TIMEOUT_MESSAGE
    rescue Net::OpenTimeout
      raise Exception, OPEN_TIMEOUT_MESSAGE
    end
  end

  class JsonFormatter
    def self.format(string)
      json = JSON.parse(string)
      (json.is_a?(Array) || json.is_a?(Hash)) ? JSON.pretty_generate(json) : string
    rescue JSON::ParserError, TypeError
      string
    end
  end
end
