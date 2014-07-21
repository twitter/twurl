require File.dirname(__FILE__) + '/test_helper'

class Twurl::AppOnlyOAuthClient::AbstractClientTest < Minitest::Test
  attr_reader :client, :options
  def setup
    Twurl::RCFile.clear
    Twurl::OAuthClient.instance_variable_set(:@rcfile, nil)

    @options                = Twurl::Options.test_app_only_exemplar
    @client                 = Twurl::AppOnlyOAuthClient.test_exemplar
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

class Twurl::AppOnlyOAuthClient::BasicMethods < Twurl::AppOnlyOAuthClient::AbstractClientTest

  def test_request_data
    data = client.send(:request_data)
    assert_equal 'client_credentials', data['grant_type']
  end

  def test_request_authorize_headers
    mock(client).authorization_header.returns({'Authorization'=>'auth'})

    headers = client.send(:request_authorize_headers)
    assert_equal 'application/x-www-form-urlencoded;charset=UTF-8', headers['Content-Type']
    assert_equal 'auth', headers['Authorization']
  end

  def test_authorization_header
    mock(Base64).strict_encode64("#{options.consumer_key}:#{options.consumer_secret}").returns('base64token')
    header = client.send(:authorization_header)

    assert_equal "Basic base64token", header['Authorization']
  end

  def test_needs_to_authorize?
    fake_response = {:access_token => "bearer"}
    mock(client).token_request.returns(fake_response)

    assert client.needs_to_authorize?, 'token should be nil'
    client.exchange_credentials_for_access_token
    assert !client.needs_to_authorize?, 'token should be valid'
  end

  def test_oauth_consumer_options
    consumer_options = client.oauth_consumer_options
    assert_equal "https://api.twitter.com", consumer_options[:site]
    assert_equal "/oauth2/token", consumer_options[:access_token_path]
  end
end

class Twurl::AppOnlyOAuthClient::ClientLoadingForUsernameTest < Twurl::AppOnlyOAuthClient::AbstractClientTest
  def test_loading_app_only_username
    mock(Twurl::OAuthClient).load_client_for_app_only(client.consumer_key).times(1)
    mock(Twurl::OAuthClient.rcfile).is_app_only?(client.username).times(1).returns(true)

    client_from_file = Twurl::OAuthClient.load_client_for_username_and_consumer_key(client.username, client.consumer_key)
  end
end

class Twurl::AppOnlyOAuthClient::NewAppOnlyClientLoadingTest < Twurl::AppOnlyOAuthClient::AbstractClientTest
  def test_loading_client_from_file
    Twurl::RCFile.clear
    mock(Twurl::OAuthClient.rcfile).save.times(1)

    Twurl::OAuthClient.rcfile << client
    assert_equal [client.username, client.consumer_key], Twurl::OAuthClient.rcfile.default_profile

    client_from_file = Twurl::OAuthClient.load_default_client

    assert_equal client.to_hash, client_from_file.to_hash
  end
end

class Twurl::AppOnlyOAuthClient::CredentialsForAppOnlyAccessTokenExchangeTest < Twurl::AppOnlyOAuthClient::AbstractClientTest
  def test_successful_exchange_parses_token_from_response_body
    parsed_response = {:access_token       => "AAAAAAAA123456789",
                       :token_type         => "bearer"}

    mock(client).token_request().returns(parsed_response)

    assert client.needs_to_authorize?
    client.exchange_credentials_for_access_token
    assert !client.needs_to_authorize?
  end
end

class Twurl::AppOnlyOAuthClient::PerformingRequestsFromAppOnlyClient < Twurl::AppOnlyOAuthClient::AbstractClientTest
  def test_request_is_made_using_client
    http = client.send(:http_client) #memoize the http client instance
    mock(client).http_client.returns http

    mock(http).request(satisfy { |req|
                                 req.is_a?(Net::HTTP::Get) && (req.path == options.path)
                               })
    client.perform_request_from_options(options)
  end
end