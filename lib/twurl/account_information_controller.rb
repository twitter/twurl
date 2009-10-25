module Twurl
  class AccountInformationController < AbstractCommandController
    def dispatch
      rcfile = OAuthClient.rcfile
      if rcfile.empty?
        CLI.puts "No authorized accounts"
      else
        rcfile.profiles.each do |account_name, configurations|
          CLI.puts account_name
          configurations.each do |consumer_key, _|
            account_summary = "  #{consumer_key}"
            account_summary << " (default)" if rcfile.default_profile == [account_name, consumer_key]
            CLI.puts account_summary
          end
        end
      end
    end
  end
end