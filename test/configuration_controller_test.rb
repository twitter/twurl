require File.dirname(__FILE__) + '/test_helper'

class Twurl::ConfigurationController::DispatchTest < Minitest::Test
  def test_error_message_is_displayed_if_setting_is_unrecognized
    options = Twurl::Options.test_exemplar
    client  = Twurl::OAuthClient.test_exemplar

    options.subcommands = ['unrecognized', 'value']

    mock(Twurl::CLI).puts(Twurl::ConfigurationController::UNRECOGNIZED_SETTING_MESSAGE % 'unrecognized').times(1)
    mock(Twurl::OAuthClient.rcfile).save.times(0)

    controller = Twurl::ConfigurationController.new(client, options)
    controller.dispatch
  end
end

class Twurl::ConfigurationController::DispatchDefaultSettingTest < Minitest::Test
  def test_setting_default_profile_just_by_username
    options = Twurl::Options.test_exemplar
    client  = Twurl::OAuthClient.test_exemplar

    options.subcommands = ['default', client.username]
    mock(Twurl::OAuthClient).load_client_for_username(client.username).times(1) { client }
    mock(Twurl::OAuthClient.rcfile).default_profile = client
    mock(Twurl::OAuthClient.rcfile).save.times(1)

    controller = Twurl::ConfigurationController.new(client, options)
    controller.dispatch
  end

  def test_setting_default_profile_by_username_and_consumer_key
    options = Twurl::Options.test_exemplar
    client  = Twurl::OAuthClient.test_exemplar

    options.subcommands = ['default', client.username, client.consumer_key]
    mock(Twurl::OAuthClient).load_client_for_username_and_consumer_key(client.username, client.consumer_key).times(1) { client }
    mock(Twurl::OAuthClient.rcfile).default_profile = client
    mock(Twurl::OAuthClient.rcfile).save.times(1)

    controller = Twurl::ConfigurationController.new(client, options)
    controller.dispatch
  end
end
