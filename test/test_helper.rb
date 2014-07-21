require 'simplecov'
require 'coveralls'

SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

SimpleCov.start

require 'twurl'
require 'minitest/autorun'
require 'rr'

Twurl::RCFile.directory = ENV['TMPDIR']

module Twurl
  class RCFile
    class << self
      def clear
        begin
          # Make sure we don't do any disk IO in these tests
          File.unlink(file_path)
        rescue Errno::ENOENT
          # Do nothing
        end
      end
    end
  end

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

      def test_app_only_exemplar
        options                 = new
        options.app_only        = true
        options.username        = 'app-only'
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

  class AppOnlyOAuthClient
    class << self
      def test_exemplar
        options = Twurl::Options.test_app_only_exemplar
        Twurl::OAuthClient.load_new_client_for_app_only(options)
      end
    end
  end
end
