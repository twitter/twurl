require 'simplecov'
require 'coveralls'

SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

SimpleCov.start

require 'twurl'
require 'minitest/autorun'
require 'rr'

Twurl::RCFile.directory = ENV['TMPDIR']

module Twurl
  class Options
    class << self
      def test_exemplar
        options                 = new
        options.username        = 'exemplar_user_name'
        options.password        = 'secret'
        options.consumer_key    = '123456789'
        options.consumer_secret = '987654321'
        options.subcommands     = []
        options
      end
    end
  end

  class OAuthClient
    class << self
      def test_exemplar(overrides = {})
        options = Twurl::Options.test_exemplar

        overrides.each do |attribute, value|
          options.send("#{attribute}=", value)
        end

        load_new_client_from_options(options)
      end
    end
  end
end
