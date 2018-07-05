require File.dirname(__FILE__) + '/test_helper'

class Twurl::CLI::OptionParsingTest < Minitest::Test
  TEST_PATH = '/1.1/url/does/not/matter.json'

  module CommandParsingTests
    def test_no_command_specified_falls_to_default_command
      options = Twurl::CLI.parse_options([TEST_PATH])
      assert_equal Twurl::CLI::DEFAULT_COMMAND, options.command
    end

    def test_supported_command_specified_extracts_the_command
      expected_command = Twurl::CLI::SUPPORTED_COMMANDS.first
      options = Twurl::CLI.parse_options([expected_command])
      assert_equal expected_command, options.command
    end

    def test_unsupported_command_specified_sets_default_command
      unsupported_command = 'unsupported'
      options = Twurl::CLI.parse_options([TEST_PATH, unsupported_command])
      assert_equal Twurl::CLI::DEFAULT_COMMAND, options.command
    end
  end
  include CommandParsingTests

  module PathParsingTests
    def test_missing_path_throws_no_path_found
      stub(Twurl::CLI).puts
      assert_raises Twurl::CLI::NoPathFound do
        Twurl::CLI.parse_options([])
      end
    end

    def test_uri_params_are_encoded
      options = Twurl::CLI.parse_options(["/1.1/url?baz=bamf:rofl"])
      assert_equal options.path, "/1.1/url?baz=bamf%3Arofl"
    end
  end
  include PathParsingTests

  module RequestMethodParsingTests
    def test_request_method_is_default_if_unspecified
      options = Twurl::CLI.parse_options([TEST_PATH])
      assert_equal Twurl::Options::DEFAULT_REQUEST_METHOD, options.request_method
    end

    def test_specifying_a_request_method_extracts_and_normalizes_request_method
      variations = [%w[-X put], %w[-X PUT], %w[--request-method PUT], %w[--request-method put]]
      variations.each do |option_variation|
        order_variant_1 = [option_variation, TEST_PATH].flatten
        order_variant_2 = [TEST_PATH, option_variation].flatten
        [order_variant_1, order_variant_2].each do |args|
          options = Twurl::CLI.parse_options(args)
          assert_equal 'put', options.request_method
        end
      end
    end

    def test_specifying_unsupported_request_method_returns_an_error
      Twurl::CLI.parse_options([TEST_PATH, '-X', 'UNSUPPORTED'])
    end
  end
  include RequestMethodParsingTests

  module OAuthClientOptionParsingTests
    def test_extracting_the_consumer_key
      mock(Twurl::CLI).prompt_for('Consumer key').never

      options = Twurl::CLI.parse_options([TEST_PATH, '-c', 'the-key'])
      assert_equal 'the-key', options.consumer_key
    end

    def test_extracting_the_token_secret
      options = Twurl::CLI.parse_options([TEST_PATH, '-S', 'the-secret'])
      assert_equal 'the-secret', options.token_secret
    end

    def test_consumer_key_option_with_no_value_prompts_user_for_value
      mock(Twurl::CLI).prompt_for('Consumer key').times(1) { 'inputted-key'}
      options = Twurl::CLI.parse_options([TEST_PATH, '-c'])
      assert_equal 'inputted-key', options.consumer_key
    end
  end
  include OAuthClientOptionParsingTests

  module DataParsingTests
    def test_extracting_a_single_key_value_pair
      options = Twurl::CLI.parse_options([TEST_PATH, '-d', 'key=value'])
      assert_equal({'key' => 'value'}, options.data)

      options = Twurl::CLI.parse_options([TEST_PATH, '--data', 'key=value'])
      assert_equal({'key' => 'value'}, options.data)
    end

    def test_passing_data_and_no_explicit_request_method_defaults_request_method_to_post
      options = Twurl::CLI.parse_options([TEST_PATH, '-d', 'key=value'])
      assert_equal 'post', options.request_method
    end

    def test_passing_data_and_an_explicit_request_method_uses_the_specified_method
      options = Twurl::CLI.parse_options([TEST_PATH, '-d', 'key=value', '-X', 'DELETE'])
      assert_equal({'key' => 'value'}, options.data)
      assert_equal 'delete', options.request_method
    end

    def test_multiple_pairs_when_option_is_specified_multiple_times_on_command_line_collects_all
      options = Twurl::CLI.parse_options([TEST_PATH, '-d', 'key=value', '-d', 'another=pair'])
      assert_equal({'key' => 'value', 'another' => 'pair'}, options.data)
    end

    def test_multiple_pairs_separated_by_ampersand_are_all_captured
      options = Twurl::CLI.parse_options([TEST_PATH, '-d', 'key=value&another=pair'])
      assert_equal({'key' => 'value', 'another' => 'pair'}, options.data)
    end

    def test_extracting_an_empty_key_value_pair
      options = Twurl::CLI.parse_options([TEST_PATH, '-d', 'key='])
      assert_equal({'key' => ''}, options.data)

      options = Twurl::CLI.parse_options([TEST_PATH, '--data', 'key='])
      assert_equal({'key' => ''}, options.data)
    end
  end
  include DataParsingTests

  module RawDataParsingTests
    def test_extracting_a_single_key_value_pair
      options = Twurl::CLI.parse_options([TEST_PATH, '-r', 'key=value'])
      assert_equal({'key' => 'value'}, options.data)

      options = Twurl::CLI.parse_options([TEST_PATH, '--raw-data', 'key=value'])
      assert_equal({'key' => 'value'}, options.data)
    end

    def test_with_special_to_url_characters_in_value
      options = Twurl::CLI.parse_options([TEST_PATH, '-r', 'key=a+%26%26+b+%2B%2B+c'])
      assert_equal({'key' => 'a && b ++ c'}, options.data)
    end

    def test_passing_data_and_no_explicit_request_method_defaults_request_method_to_post
      options = Twurl::CLI.parse_options([TEST_PATH, '-r', 'key=value'])
      assert_equal 'post', options.request_method
    end

    def test_passing_data_and_an_explicit_request_method_uses_the_specified_method
      options = Twurl::CLI.parse_options([TEST_PATH, '-r', 'key=value', '-X', 'DELETE'])
      assert_equal({'key' => 'value'}, options.data)
      assert_equal 'delete', options.request_method
    end

    def test_multiple_pairs_when_option_is_specified_multiple_times_on_command_line_collects_all
      options = Twurl::CLI.parse_options([TEST_PATH, '-r', 'key=value', '-d', 'another=pair'])
      assert_equal({'key' => 'value', 'another' => 'pair'}, options.data)
    end

    def test_multiple_pairs_separated_by_ampersand_are_all_captured
      options = Twurl::CLI.parse_options([TEST_PATH, '-r', 'key=value+%26+value&another=pair'])
      assert_equal({'key' => 'value & value', 'another' => 'pair'}, options.data)
    end

    def test_extracting_an_empty_key_value_pair
      options = Twurl::CLI.parse_options([TEST_PATH, '-r', 'key='])
      assert_equal({'key' => ''}, options.data)

      options = Twurl::CLI.parse_options([TEST_PATH, '--raw-data', 'key='])
      assert_equal({'key' => ''}, options.data)
    end
  end
  include RawDataParsingTests

  module HeaderParsingTests
    def test_extracting_a_single_header
      options = Twurl::CLI.parse_options([TEST_PATH, '-A', 'Key: Value'])
      assert_equal({'Key' => 'Value'}, options.headers)

      options = Twurl::CLI.parse_options([TEST_PATH, '--header', 'Key: Value'])
      assert_equal({'Key' => 'Value'}, options.headers)
    end

    def test_multiple_headers_when_option_is_specified_multiple_times_on_command_line_collects_all
      options = Twurl::CLI.parse_options([TEST_PATH, '-A', 'Key: Value', '-A', 'Another: Pair'])
      assert_equal({'Key' => 'Value', 'Another' => 'Pair'}, options.headers)
    end
  end
  include HeaderParsingTests

  module SSLDisablingTests
    def test_ssl_is_on_by_default
      options = Twurl::CLI.parse_options([TEST_PATH])
      assert options.ssl?
    end

    def test_passing_no_ssl_option_disables_ssl
      ['-U', '--no-ssl'].each do |switch|
        options = Twurl::CLI.parse_options([TEST_PATH, switch])
        assert !options.ssl?
      end
    end
  end
  include SSLDisablingTests

  module HostOptionTests
    def test_not_specifying_host_sets_it_to_the_default
      options = Twurl::CLI.parse_options([TEST_PATH])
      assert_equal Twurl::Options::DEFAULT_HOST, options.host
    end

    def test_setting_host_updates_to_requested_value
      custom_host = 'localhost:3000'
      assert Twurl::Options::DEFAULT_HOST != custom_host

      [[TEST_PATH, '-H', custom_host], [TEST_PATH, '--host', custom_host]].each do |option_combination|
        options = Twurl::CLI.parse_options(option_combination)
        assert_equal custom_host, options.host
      end
    end

    def test_protocol_is_stripped_from_host
      custom_host = 'localhost:3000'
      options = Twurl::CLI.parse_options([TEST_PATH, '-H', "https://"+custom_host])
      assert_equal custom_host, options.host
    end
  end
  include HostOptionTests

  module ProxyOptionTests
    def test_not_specifying_proxy_sets_it_to_nil
      options = Twurl::CLI.parse_options([TEST_PATH])
      assert_equal nil, options.proxy
    end

    def test_setting_proxy_updates_to_requested_value
      custom_proxy = 'localhost:80'

      [[TEST_PATH, '-P', custom_proxy], [TEST_PATH, '--proxy', custom_proxy]].each do |option_combination|
        options = Twurl::CLI.parse_options(option_combination)
        assert_equal custom_proxy, options.proxy
      end
    end
  end
  include ProxyOptionTests
end
