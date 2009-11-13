module Twurl
  class ConfigurationController < AbstractCommandController
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
        CLI.puts "Unknown configuration setting: '#{options.subcommands.first}'"
      end
    end
  end
end