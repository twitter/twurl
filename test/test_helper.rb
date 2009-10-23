$:.unshift File.dirname(__FILE__) + '/../lib'
require 'twurl'
require 'test/unit'
require 'rr'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end

Twurl::RCFile.directory = ENV['TMPDIR']

module Twurl
  class OAuthClient
    class << self
      def test_exemplar(overrides = {})
        options                 = CLI::Options.new
        options.username        = 'exemplar_user_name'
        options.password        = 'secret'
        options.consumer_key    = '123456789'
        options.consumer_secret = '987654321'

        overrides.each do |attribute, value|
          options.send("#{attribute}=", value)
        end

        load_new_client_from_options(options)
      end
    end
  end
end
