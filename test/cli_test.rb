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

  module RequestMethodParsingTests
    def test_request_method_is_default_if_unspecified
      options = Twurl::CLI.parse_options(['/1/url/does/not/matter.xml'])
      assert_equal Twurl::CLI::DEFAULT_REQUEST_METHOD, options.request_method
    end

    def test_specifying_a_request_method_extracts_and_normalizes_request_method
      variations = [%w[-X put], %w[-X PUT], %w[--request-method PUT], %w[--request-method put]]
      variations.each do |option_variation|
        path = '/1/url/does/not/matter.xml'
        order_variant_1 = [option_variation, path].flatten
        order_variant_2 = [path, option_variation].flatten
        [order_variant_1, order_variant_2].each do |args|
          options = Twurl::CLI.parse_options(args)
          assert_equal 'put', options.request_method
        end
      end
    end

    def test_specifying_unsupported_request_method_returns_an_error
      Twurl::CLI.parse_options(['-X', 'UNSUPPORTED'])
    end
  end
  include RequestMethodParsingTests

  module DataParsingTests
    def test_extracting_a_single_key_value_pair
      options = Twurl::CLI.parse_options(['-d', 'key=value'])
      assert_equal({'key' => 'value'}, options.data)

      options = Twurl::CLI.parse_options(['--data', 'key=value'])
      assert_equal({'key' => 'value'}, options.data)
    end

    def test_passing_data_and_no_explicit_request_method_defaults_request_method_to_post
      options = Twurl::CLI.parse_options(['-d', 'key=value'])
      assert_equal 'post', options.request_method
    end

    def test_passing_data_and_an_explicit_request_method_uses_the_specified_method
      options = Twurl::CLI.parse_options(['-d', 'key=value', '-X', 'DELETE'])
      assert_equal({'key' => 'value'}, options.data)
      assert_equal 'delete', options.request_method
    end

    def test_multiple_pairs_when_option_is_specified_multiple_times_on_command_line_collects_all
      options = Twurl::CLI.parse_options(['-d', 'key=value', '-d', 'another=pair'])
      assert_equal({'key' => 'value', 'another' => 'pair'}, options.data)
    end

    def test_multiple_pairs_separated_by_ampersand_are_all_captured
      options = Twurl::CLI.parse_options(['-d', 'key=value&another=pair'])
      assert_equal({'key' => 'value', 'another' => 'pair'}, options.data)
    end
  end
  include DataParsingTests
end