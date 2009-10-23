module Twurl
  class AuthorizationController < AbstractCommandController
    AUTHORIZATION_FAILED_MESSAGE = "Authorization failed. Check that your consumer key and secret are correct, as well as username and password."
    def dispatch
      client.exchange_credentials_for_access_token
      client.save
    rescue OAuth::Unauthorized
      abort(AUTHORIZATION_FAILED_MESSAGE)
    end
  end
end