module Twurl
  class AppOnlyTokenInformationController < AbstractCommandController
    NO_ISSUED_TOKENS_MESSAGE = "No issued application-only (Bearer) tokens"

    def dispatch
      rcfile = OAuthClient.rcfile
      if rcfile.empty? || rcfile.bearer_tokens.nil?
        CLI.puts NO_ISSUED_TOKENS_MESSAGE
      else
        tokens = rcfile.bearer_tokens
        CLI.puts "[consumer_key: bearer_token]"
        tokens.each_key do |consumer_key|
          CLI.puts "#{consumer_key}: (omitted)"
        end
      end
    end
  end
end
