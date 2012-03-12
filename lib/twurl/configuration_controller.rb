module Twurl
  class ConfigurationController < AbstractCommandController
    UNRECOGNIZED_SETTING_MESSAGE = "Unknown configuration setting: '%s'"
    def dispatch
      case options.subcommands.first
      when 'default'
        if profile = case options.subcommands.size
                     when 2
                       OAuthClient.load_client_for_username(options.subcommands.last)
                     when 3
                       OAuthClient.load_client_for_username_and_consumer_key(*options.subcommands[-2, 2])
                     end

          OAuthClient.rcfile.default_profile = profile
          OAuthClient.rcfile.save
        end
      else
        CLI.puts(UNRECOGNIZED_SETTING_MESSAGE % options.subcommands.first)
      end
    end
  end
end
