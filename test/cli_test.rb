require File.dirname(__FILE__) + '/test_helper'

class Twurl::CLI::DispatchingTest < Test::Unit::TestCase
  attr_reader :options
  def setup
    @options = OpenStruct.new
  end

  def test_unrecognized_commands_abort_execution_with_an_error
    options.command = 'unrecognized'
    mock(Twurl::CLI).abort("Unsupported command: unrecognized")

    Twurl::CLI.dispatch(options)
  end
end

class Twurl::CLI::OptionParsingTest < Test::Unit::TestCase
  module CommandParsingTests
    def test_no_command_specified_falls_to_default_command
      options = Twurl::CLI.parse_options(['/1/url/does/not/matter.xml'])
      assert_equal Twurl::CLI::DEFAULT_COMMAND, options.command
    end

    def test_supported_command_specified_extracts_the_command
      expected_command = Twurl::CLI::SUPPORTED_COMMANDS.first
      options = Twurl::CLI.parse_options([expected_command])
      assert_equal expected_command, options.command
    end

    def test_unsupported_command_specified_sets_default_command
      unsupported_command = 'unsupported'
      options = Twurl::CLI.parse_options([unsupported_command])
      assert_equal Twurl::CLI::DEFAULT_COMMAND, options.command
    end
  end
  include CommandParsingTests
end