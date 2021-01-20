require File.dirname(__FILE__) + '/test_helper'

class Twurl::Options::Test < Minitest::Test
  attr_reader :options
  def setup
    @options = Twurl::Options.new
  end

  def test_base_url_is_built_from_host_option
    options = Twurl::CLI.parse_options(['-H', 'ads-api.twitter.com'])

    assert_equal 'https://ads-api.twitter.com', options.base_url
  end
end
