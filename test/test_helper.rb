require 'simplecov'
require 'coveralls'

SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

SimpleCov.start

require 'twurl'
require 'minitest/autorun'
require 'rr'

Twurl::RCFile.directory = ENV['TMPDIR'] || File.dirname(__FILE__)

module Twurl
  class Options
    class << self
      def test_exemplar
        options = Twurl::CLI.parse_options([
          '-u', 'exemplar_user_name',
          '-c', '123456789',
          '-s', '987654321'
        ])
        options
      end

      def test_app_only_exemplar
        options = Twurl::CLI.parse_options([
          '--bearer',
          '-c', '123456789',
          '-s', '987654321'
        ])
        options.bearer_token = 'test_bearer_token'
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

  class AppOnlyOAuthClient
    class << self
      def test_app_only_exemplar
        options = Twurl::Options.test_app_only_exemplar
        Twurl::AppOnlyOAuthClient.new(
          options.oauth_client_options.merge(
            'bearer_token' => options.bearer_token
          )
        )
      end
    end
  end
end
