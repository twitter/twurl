require File.dirname(__FILE__) + '/test_helper'

class Twurl::OAuthClient::AbstractOAuthClientTest < Minitest::Test
  attr_reader :client, :options
  def setup
    Twurl::RCFile.clear
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
    Twurl::RCFile.clear
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
  def test_if_username_is_supplied_and_no_profile_exists_for_username_then_new_client_is_created
    mock(Twurl::OAuthClient).load_client_for_username(options.username).never
    mock(Twurl::OAuthClient).load_new_client_from_options(options).times(1)
    mock(Twurl::OAuthClient).load_default_client.never

    Twurl::OAuthClient.load_from_options(options)
  end

  def test_if_username_is_supplied_and_profile_exists_for_username_then_client_is_loaded
    mock(Twurl::OAuthClient.rcfile).save.times(1)
    Twurl::OAuthClient.rcfile << client

    mock(Twurl::OAuthClient).load_client_for_username_and_consumer_key(options.username, options.consumer_key).times(1)
    mock(Twurl::OAuthClient).load_new_client_from_options(options).never
    mock(Twurl::OAuthClient).load_default_client.never

    Twurl::OAuthClient.load_from_options(options)
  end

  def test_if_username_is_not_provided_then_the_default_client_is_loaded
    options.username = nil

    mock(Twurl::OAuthClient).load_client_for_username(options.username).never
    mock(Twurl::OAuthClient).load_new_client_from_options(options).never
    mock(Twurl::OAuthClient).load_default_client.times(1)

    Twurl::OAuthClient.load_from_options(options)
  end

  def test_if_authorize_app_only_client_is_loaded
    options = Twurl::Options.test_app_only_exemplar
    options.command = 'authorize'

    mock(Twurl::OAuthClient).load_client_for_username_and_consumer_key(options.username, options.consumer_key).never
    mock(Twurl::OAuthClient).load_new_client_from_options(options).never
    mock(Twurl::OAuthClient).load_default_client.never
    mock(Twurl::OAuthClient).load_new_client_for_app_only(options).times(1)

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
      Twurl::OAuthClient.load_default_client
    end
  end

  def test_loading_default_client_from_file
    mock(Twurl::OAuthClient.rcfile).save.times(1)

    Twurl::OAuthClient.rcfile << client
    assert_equal [client.username, client.consumer_key], Twurl::OAuthClient.rcfile.default_profile

    client_from_file = Twurl::OAuthClient.load_default_client

    assert_equal client.to_hash, client_from_file.to_hash
  end
end

class Twurl::OAuthClient::NewClientLoadingFromOptionsTest < Twurl::OAuthClient::AbstractOAuthClientTest
  attr_reader :new_client
  def setup
    super
    @new_client = Twurl::OAuthClient.load_new_client_from_options(options)
  end

  def test_password_is_included
    assert_equal options.password, new_client.password
  end

  def test_oauth_options_are_passed_through
    assert_equal client.to_hash, new_client.to_hash
  end
end

class Twurl::OAuthClient::PerformingRequestsFromOptionsTest < Twurl::OAuthClient::AbstractOAuthClientTest
  def test_request_is_made_using_request_method_and_path_and_data_in_options
    client = Twurl::OAuthClient.test_exemplar
    mock(client.consumer.http).request(satisfy { |req|
                                         req.is_a?(Net::HTTP::Get) && (req.path == options.path)
                                       })

    client.perform_request_from_options(options)
  end
end

class Twurl::OAuthClient::CredentialsForAccessTokenExchangeTest < Twurl::OAuthClient::AbstractOAuthClientTest
  def test_successful_exchange_parses_token_and_secret_from_response_body
    parsed_response = {:oauth_token        => "123456789",
                       :oauth_token_secret => "abcdefghi",
                       :user_id            => "3191321",
                       :screen_name        => "noradio",
                       :x_auth_expires     => "0"}

    mock(client.consumer).
      token_request(:post,
                    client.consumer.access_token_path,
                    nil,
                    {},
                    client.client_auth_parameters) { parsed_response }

   assert client.needs_to_authorize?
   client.exchange_credentials_for_access_token
   assert !client.needs_to_authorize?
  end
end
