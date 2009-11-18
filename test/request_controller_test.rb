require File.dirname(__FILE__) + '/test_helper'

class Twurl::RequestController::AbstractTestCase < Test::Unit::TestCase
  attr_reader :options, :client, :controller
  def setup
    Twurl::CLI.output = StringIO.new
    @options    = Twurl::Options.test_exemplar
    @client     = Twurl::OAuthClient.test_exemplar
    @controller = Twurl::RequestController.new(client, options)
  end

  def teardown
    super
    Twurl::CLI.output = STDOUT
  end

  def test_nothing
    # Appeasing test/unit
  end
end

class Twurl::RequestController::DispatchTest < Twurl::RequestController::AbstractTestCase
  def test_request_will_be_made_if_client_is_authorized
    mock(client).needs_to_authorize? { false }.times(1)
    mock(controller).perform_request.times(1)

    controller.dispatch
  end

  def test_request_will_not_be_made_if_client_is_not_authorized
    mock(client).needs_to_authorize? { true }.times(1)
    mock(controller).perform_request.never

    assert_raises Twurl::Exception do
      controller.dispatch
    end
  end
end

class Twurl::RequestController::RequestTest < Twurl::RequestController::AbstractTestCase
  def test_request_response_is_written_to_output
    expected_body = 'this is a fake response body'
    response      = Object.new
    mock(response).body.times(1) { expected_body }
    mock(client).perform_request_from_options(options).times(1) { response }

    controller.perform_request

    assert_equal expected_body, Twurl::CLI.output.string.chomp
  end
end