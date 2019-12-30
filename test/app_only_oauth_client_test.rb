require File.dirname(__FILE__) + '/test_helper'

class Twurl::AppOnlyOAuthClient::AbstractClientTest < Minitest::Test
  attr_reader :client, :options
  def setup
    Twurl::OAuthClient.instance_variable_set(:@rcfile, nil)

    @options                = Twurl::Options.test_app_only_exemplar
    @client                 = Twurl::AppOnlyOAuthClient.test_app_only_exemplar
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

class Twurl::AppOnlyOAuthClient::BasicMethods < Twurl::AppOnlyOAuthClient::AbstractClientTest
  def test_needs_to_authorize?
    client = Twurl::AppOnlyOAuthClient.new(
      options.oauth_client_options.merge(
        'bearer_token' => nil
      )
    )

    fake_response = {:access_token => "test_bearer_token"}
    mock(client).fetch_oauth2_token { fake_response }

    assert client.needs_to_authorize?, 'token should be nil'
    client.exchange_credentials_for_access_token
    assert !client.needs_to_authorize?, 'token should be exist'
  end
end

class Twurl::AppOnlyOAuthClient::ClientLoadingTest < Twurl::AppOnlyOAuthClient::AbstractClientTest
  def test_attempting_to_load_a_bearer_token_from_non_authed_consumer_key_fails
    mock(Twurl::OAuthClient.rcfile).save.times(any_times)
    Twurl::OAuthClient.rcfile.bearer_token(options.consumer_key, options.bearer_token)

    assert Twurl::OAuthClient.rcfile.bearer_tokens.to_hash[options.consumer_key]
    assert_nil Twurl::OAuthClient.rcfile.bearer_tokens.to_hash[:invalid_consumer_key]

    options.consumer_key = 'invalid_consumer_key'
    assert_raises Twurl::Exception do
      Twurl::OAuthClient.load_default_client(options)
    end
  end
end

class Twurl::AppOnlyOAuthClient::PerformingRequestsFromAppOnlyClient < Twurl::AppOnlyOAuthClient::AbstractClientTest
  def test_request_is_made_using_request_method_and_path_and_data_in_options
    http = client.send(:http_client)
    mock(client).http_client { http }
    mock(http).request(
      satisfy { |req| req.is_a?(Net::HTTP::Get) && (req.path == options.path) }
    )
    client.perform_request_from_options(options)
  end

  def test_user_agent_request_header_is_set
    expected_ua_string = "twurl version: #{Twurl::Version} platform: #{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_PLATFORM})"

    http = client.send(:http_client)
    mock(client).http_client { http }
    mock(http).request(
      satisfy { |req|
        req.is_a?(Net::HTTP::Get) &&
        req['user-agent'] == expected_ua_string
      }
    )
    client.perform_request_from_options(options)
  end

  def test_request_options_are_setable
    http = client.send(:http_client)
    assert_equal 60, http.read_timeout

    options.timeout = 10    
    http = client.send(:http_client)

    assert_equal 10, http.read_timeout
  end
end
