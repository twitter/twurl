module Twurl
  class AccountInformationController < AbstractCommandController
    def dispatch
      rcfile = OAuthClient.rcfile
      if rcfile.empty?
        CLI.puts "No authorized accounts"
      else
        rcfile.profiles.each do |account_name, configuration|
          account_summary = "#{account_name}: #{configuration['consumer_key']}"
          account_summary << " (default)" if rcfile.default_profile == account_name
          CLI.puts account_summary
        end
      end
    end
  end
end