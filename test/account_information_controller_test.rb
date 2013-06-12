require File.dirname(__FILE__) + '/test_helper'

class Twurl::AccountInformationController::DispatchWithNoAuthorizedAccountsTest < Minitest::Test
  attr_reader :options, :client, :controller
  def setup
    @options    = Twurl::Options.new
    @client     = Twurl::OAuthClient.load_new_client_from_options(options)
    @controller = Twurl::AccountInformationController.new(client, options)
    mock(Twurl::OAuthClient.rcfile).empty? { true }
  end

  def test_message_indicates_when_no_accounts_are_authorized
    mock(Twurl::CLI).puts(Twurl::AccountInformationController::NO_AUTHORIZED_ACCOUNTS_MESSAGE).times(1)

    controller.dispatch
  end
end

class Twurl::AccountInformationController::DispatchWithOneAuthorizedAccountTest < Minitest::Test
  attr_reader :options, :client, :controller
  def setup
    @options    = Twurl::Options.test_exemplar
    @client     = Twurl::OAuthClient.load_new_client_from_options(options)
    mock(Twurl::OAuthClient.rcfile).save.times(1)
    Twurl::OAuthClient.rcfile << client
    @controller = Twurl::AccountInformationController.new(client, options)
  end

  def test_authorized_account_is_displayed_and_marked_as_the_default
    mock(Twurl::CLI).puts(client.username).times(1).ordered
    mock(Twurl::CLI).puts("  #{client.consumer_key} (default)").times(1).ordered

    controller.dispatch
  end
end

class Twurl::AccountInformationController::DispatchWithOneUsernameThatHasAuthorizedMultipleAccountsTest < Minitest::Test
  attr_reader :default_client_options, :default_client, :other_client_options, :other_client, :controller
  def setup
    @default_client_options = Twurl::Options.test_exemplar
    @default_client         = Twurl::OAuthClient.load_new_client_from_options(default_client_options)

    @other_client_options             = Twurl::Options.test_exemplar
    other_client_options.consumer_key = default_client_options.consumer_key.reverse
    @other_client                     = Twurl::OAuthClient.load_new_client_from_options(other_client_options)
    mock(Twurl::OAuthClient.rcfile).save.times(2)

    Twurl::OAuthClient.rcfile << default_client
    Twurl::OAuthClient.rcfile << other_client

    @controller = Twurl::AccountInformationController.new(other_client, other_client_options)
  end

  def test_authorized_account_is_displayed_and_marked_as_the_default
    mock(Twurl::CLI).puts(default_client.username).times(1)
    mock(Twurl::CLI).puts("  #{default_client.consumer_key} (default)").times(1)
    mock(Twurl::CLI).puts("  #{other_client.consumer_key}").times(1)

    controller.dispatch
  end
end
