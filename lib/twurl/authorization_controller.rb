module Twurl
  class AuthorizationController < AbstractCommandController
    AUTHORIZATION_FAILED_MESSAGE    = "Authorization failed. Check that your consumer key and secret are correct, as well as username and password."
    AUTHORIZATION_SUCCEEDED_MESSAGE = "Authorization successful"
    def dispatch
      client.exchange_credentials_for_access_token
      client.save
      CLI.puts AUTHORIZATION_SUCCEEDED_MESSAGE
    rescue OAuth::Unauthorized
      raise Exception, AUTHORIZATION_FAILED_MESSAGE
    end
  end
end
