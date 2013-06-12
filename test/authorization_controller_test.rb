require File.dirname(__FILE__) + '/test_helper'

class Twurl::AuthorizationController::DispatchTest < Minitest::Test
  attr_reader :options, :client, :controller
  def setup
    @options    = Twurl::Options.new
    @client     = Twurl::OAuthClient.load_new_client_from_options(options)
    @controller = Twurl::AuthorizationController.new(client, options)
  end

  def test_successful_authentication_saves_retrieved_access_token
    mock(client).exchange_credentials_for_access_token.times(1)
    mock(client).save.times(1)
    mock(controller).raise(Twurl::Exception, Twurl::AuthorizationController::AUTHORIZATION_FAILED_MESSAGE).never
    mock(Twurl::CLI).puts(Twurl::AuthorizationController::AUTHORIZATION_SUCCEEDED_MESSAGE).times(1)

    controller.dispatch
  end

  module ErrorCases
    def test_failed_authorization_does_not_save_client
      mock(client).exchange_credentials_for_access_token { raise OAuth::Unauthorized }
      mock(client).save.never
      mock(controller).raise(Twurl::Exception, Twurl::AuthorizationController::AUTHORIZATION_FAILED_MESSAGE).times(1)

      controller.dispatch
    end
  end
  include ErrorCases
end
