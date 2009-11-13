module Twurl
  class AliasesController < AbstractCommandController
    def dispatch
      case options.subcommands.size
      when 0
        aliases = OAuthClient.rcfile.aliases
        aliases.keys.sort.each do |name|
          CLI.puts "#{name}: #{aliases[name]}"
        end
      when 1
        OAuthClient.rcfile.alias(options.subcommands.first, options.path)
      end
    end
  end
end