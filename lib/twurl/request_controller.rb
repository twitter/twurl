module Twurl
  class RequestController < AbstractCommandController
    def dispatch
      if client.needs_to_authorize?
        abort("You need to authorize first.")
      end
      perform_request_from_options(options)
    end

    def perform_request_from_options(options)
      puts client.send(options.request_method, options.path, options.data)
    end
  end
end