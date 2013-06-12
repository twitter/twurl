require File.dirname(__FILE__) + '/test_helper'

class Twurl::AliasesController::DispatchTest < Minitest::Test
  attr_reader :options, :client
  def setup
    @options = Twurl::Options.test_exemplar
    @client  = Twurl::OAuthClient.test_exemplar

    # Clean slate
    if Twurl::OAuthClient.rcfile.aliases
      Twurl::OAuthClient.rcfile.aliases.clear
    end

    stub(Twurl::OAuthClient.rcfile).save
  end

  def test_when_no_subcommands_are_provided_and_no_aliases_exist_nothing_is_displayed
    assert options.subcommands.empty?
    mock(Twurl::CLI).puts(Twurl::AliasesController::NO_ALIASES_MESSAGE).times(1)

    controller = Twurl::AliasesController.new(client, options)
    controller.dispatch
  end

  def test_when_no_subcommands_are_provided_and_aliases_exist_they_are_displayed
    assert options.subcommands.empty?

    Twurl::OAuthClient.rcfile.alias('h', '/1.1/statuses/home_timeline.json')
    mock(Twurl::CLI).puts("h: /1.1/statuses/home_timeline.json").times(1)

    controller = Twurl::AliasesController.new(client, options)
    controller.dispatch
  end

  def test_when_alias_and_value_are_provided_they_are_added
    options.subcommands = ['h']
    options.path        = '/1.1/statuses/home_timeline.json'
    mock(Twurl::OAuthClient.rcfile).alias('h', '/1.1/statuses/home_timeline.json').times(1)

    controller = Twurl::AliasesController.new(client, options)
    controller.dispatch
  end

  def test_when_no_path_is_provided_nothing_happens
    options.subcommands = ['a']
    assert_nil options.path

    mock(Twurl::CLI).puts(Twurl::AliasesController::NO_PATH_PROVIDED_MESSAGE).times(1)

    controller = Twurl::AliasesController.new(client, options)
    controller.dispatch
  end
end
