require File.dirname(__FILE__) + '/test_helper'

class Twurl::OAuthClient::AbstractOAuthClientTest < Minitest::Test
  TEST_PATH = '/1.1/url/does/not/matter.json'

  attr_reader :client, :options
  def setup
    Twurl::OAuthClient.instance_variable_set(:@rcfile, nil)

    @options                = Twurl::Options.test_exemplar
    @client                 = Twurl::OAuthClient.test_exemplar
    options.base_url        = 'api.twitter.com'
    options.request_method  = 'get'
    options.path            = '/path/does/not/matter.json'
    options.data            = {}
    options.headers         = {}

    Twurl.options           = options
  end

  def teardown
    super
    Twurl.options = Twurl::Options.new
    # Make sure we don't do any disk IO in these tests
    assert !File.exist?(Twurl::RCFile.file_path)
  end

  def test_nothing
    # Appeasing test/unit
  end
end

class Twurl::OAuthClient::BasicRCFileLoadingTest < Twurl::OAuthClient::AbstractOAuthClientTest
  def test_rcfile_is_memoized
    mock.proxy(Twurl::RCFile).new.times(1)

    Twurl::OAuthClient.rcfile
    Twurl::OAuthClient.rcfile
  end

  def test_forced_reloading
    mock.proxy(Twurl::RCFile).new.times(2)

    Twurl::OAuthClient.rcfile
    Twurl::OAuthClient.rcfile(:reload)
    Twurl::OAuthClient.rcfile
  end
end

class Twurl::OAuthClient::ClientLoadingFromOptionsTest < Twurl::OAuthClient::AbstractOAuthClientTest
  def test_if_username_is_supplied_and_no_profile_exists_for_username_then_no_profile_error
    assert_raises Twurl::Exception do
      Twurl::OAuthClient.load_from_options(options)
    end
  end

  def test_if_username_is_supplied_and_profile_exists_for_username_then_client_is_loaded
    mock(Twurl::OAuthClient.rcfile).save.times(1)
    Twurl::OAuthClient.rcfile << client

    mock(Twurl::OAuthClient).load_client_for_username_and_consumer_key(options.username, options.consumer_key).times(1)
    mock(Twurl::OAuthClient).load_new_client_from_options(options).never
    mock(Twurl::OAuthClient).load_default_client(options).never

    Twurl::OAuthClient.load_from_options(options)
  end

  def test_if_username_is_not_provided_then_the_default_client_is_loaded
    options.username = nil

    mock(Twurl::OAuthClient).load_client_for_username(options.username).never
    mock(Twurl::OAuthClient).load_new_client_from_options(options).never
    mock(Twurl::OAuthClient).load_default_client(options).times(1)

    Twurl::OAuthClient.load_from_options(options)
  end

  def test_if_all_oauth_options_are_supplied_then_client_is_loaded_from_options
    options.username = nil
    options.command = 'request'
    options.access_token = 'test_access_token'
    options.token_secret = 'test_token_secret'

    mock(Twurl::OAuthClient).load_new_client_from_oauth_options(options).times(1)
    mock(Twurl::OAuthClient).load_default_client(options).never

    Twurl::OAuthClient.load_from_options(options)
  end

  def test_if_authorize_app_only_client_is_loaded
    options = Twurl::Options.test_app_only_exemplar
    options.command = 'authorize'

    mock(Twurl::OAuthClient).load_default_client.never
    mock(Twurl::OAuthClient).load_client_for_app_only_auth(options, options.consumer_key).times(1)

    Twurl::OAuthClient.load_from_options(options)
  end

  def test_if_app_only_options_is_supplied_on_request_then_app_only_client_is_loaded
    options = Twurl::Options.test_app_only_exemplar
    options.command = 'request'

    mock(Twurl::OAuthClient.rcfile).save.times(any_times)
    Twurl::OAuthClient.rcfile << client
    Twurl::OAuthClient.rcfile.bearer_token(options.consumer_key, options.bearer_token)
    mock.proxy(Twurl::OAuthClient).load_default_client(options).times(1)
    mock(Twurl::OAuthClient).load_client_for_app_only_auth(options, options.consumer_key).times(1)

    options.consumer_key = nil
    Twurl::OAuthClient.load_from_options(options)
  end

  def test_if_app_only_and_consumer_key_options_are_supplied_on_request_then_app_only_client_is_loaded
    options = Twurl::Options.test_app_only_exemplar
    options.command = 'request'

    mock(Twurl::OAuthClient).load_client_for_non_profile_app_only_auth(options).times(1)

    Twurl::OAuthClient.load_from_options(options)
  end
end

class Twurl::OAuthClient::ClientLoadingForUsernameTest < Twurl::OAuthClient::AbstractOAuthClientTest
  def test_attempting_to_load_a_username_that_is_not_in_the_file_fails
    assert_nil Twurl::OAuthClient.rcfile[client.username]

    assert_raises Twurl::Exception do
      Twurl::OAuthClient.load_client_for_username_and_consumer_key(client.username, client.consumer_key)
    end
  end

  def test_loading_a_username_that_exists
    mock(Twurl::OAuthClient.rcfile).save.times(1)

    Twurl::OAuthClient.rcfile << client

    client_from_file = Twurl::OAuthClient.load_client_for_username_and_consumer_key(client.username, client.consumer_key)
    assert_equal client.to_hash, client_from_file.to_hash
  end
end

class Twurl::OAuthClient::DefaultClientLoadingTest < Twurl::OAuthClient::AbstractOAuthClientTest
  def test_loading_default_client_when_there_is_none_fails
    assert_nil Twurl::OAuthClient.rcfile.default_profile

    assert_raises Twurl::Exception do
      Twurl::OAuthClient.load_default_client(options)
    end
  end

  def test_loading_default_client_from_file
    mock(Twurl::OAuthClient.rcfile).save.times(1)

    Twurl::OAuthClient.rcfile << client
    assert_equal [client.username, client.consumer_key], Twurl::OAuthClient.rcfile.default_profile

    client_from_file = Twurl::OAuthClient.load_default_client(options)

    assert_equal client.to_hash, client_from_file.to_hash
  end
end

class Twurl::OAuthClient::NewClientLoadingFromOptionsTest < Twurl::OAuthClient::AbstractOAuthClientTest
  attr_reader :new_client
  def setup
    super
    @new_client = Twurl::OAuthClient.load_new_client_from_options(options)
  end

  def test_oauth_options_are_passed_through
    assert_equal client.to_hash, new_client.to_hash
  end
end

class Twurl::OAuthClient::NewClientLoadingFromOauthOptionsTest < Twurl::OAuthClient::AbstractOAuthClientTest
  attr_reader :new_client
  def setup
    super
    options.access_token = 'test_access_token'
    options.token_secret = 'test_token_secret'
    @new_client = Twurl::OAuthClient.load_new_client_from_oauth_options(options)
  end

  def test_attributes_are_updated
    assert_equal options.access_token, new_client.token
    assert_equal options.token_secret, new_client.secret
  end
end

class Twurl::OAuthClient::PerformingRequestsFromOptionsTest < Twurl::OAuthClient::AbstractOAuthClientTest
  def test_request_is_made_using_request_method_and_path_and_data_in_options
    client = Twurl::OAuthClient.test_exemplar

    mock(client.consumer.http).request(
      satisfy { |req| req.is_a?(Net::HTTP::Get) && (req.path == options.path) }
    )

    client.perform_request_from_options(options)
  end

  def test_content_type_is_not_overridden_if_set_and_data_in_options
    client = Twurl::OAuthClient.test_exemplar
    options = Twurl::CLI.parse_options([TEST_PATH, '-d', '{ "foo": "bar" }', '-A', 'Content-Type: application/json'])

    mock(client.consumer.http).request(
      satisfy { |req| req.is_a?(Net::HTTP::Post) && req.content_type == 'application/json' }
    )

    client.perform_request_from_options(options)
  end

  def test_content_type_is_set_to_form_encoded_if_not_set_and_data_in_options
    client = Twurl::OAuthClient.test_exemplar
    options = Twurl::CLI.parse_options([TEST_PATH, '-d', 'foo=bar'])

    mock(client.consumer.http).request(
      satisfy { |req| req.is_a?(Net::HTTP::Post) && req.content_type == 'application/x-www-form-urlencoded' }
    )

    client.perform_request_from_options(options)
  end

  def test_post_body_is_parsed_and_escaped_properly_through_request_builder
    client = Twurl::OAuthClient.test_exemplar
    options = Twurl::CLI.parse_options([TEST_PATH, '-d', 'foo=text%26text'])

    mock(client.consumer.http).request(
      satisfy { |req|
        req.is_a?(Net::HTTP::Post) &&
        req.content_type == 'application/x-www-form-urlencoded' &&
        req.body == 'foo=text%26text'
      }
    )

    client.perform_request_from_options(options)
  end

  def test_user_agent_request_header_is_set
    client = Twurl::OAuthClient.test_exemplar
    expected_ua_string = "twurl version: #{Twurl::Version} platform: #{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_PLATFORM})"

    mock(client.consumer.http).request(
      satisfy { |req|
        req.is_a?(Net::HTTP::Get) &&
        req['user-agent'] == expected_ua_string
      }
    )

    client.perform_request_from_options(options)
  end
end

class Twurl::OAuthClient::CredentialsForAccessTokenExchangeTest < Twurl::OAuthClient::AbstractOAuthClientTest
  def test_successful_exchange_parses_token_and_secret_from_response_body
    parsed_response = {:oauth_token        => "123456789",
                       :oauth_token_secret => "abcdefghi",
                       :user_id            => "3191321",
                       :screen_name        => "noradio"
                      }

    mock(client.consumer).
      token_request(:post,
                    client.consumer.access_token_path,
                    nil,
                    {},
                   ) { parsed_response }

   assert client.needs_to_authorize?
   client.exchange_credentials_for_access_token
   assert !client.needs_to_authorize?
  end
end
