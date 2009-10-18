module Twurl
  class RCFile
    RCFILE = '.twurlrc'
    @home_directory ||= ENV['HOME']

    class << self
      attr_accessor :home_directory

      def file_path
        File.join(home_directory, RCFILE)
      end

      def write(oauth_client)
        File.open(file_path, 'w') do |rcfile|
          rcfile.write oauth_client.to_rcfile
        end
      end

      def <<(oauth_client)
      end

      def load
        YAML.load_file(file_path)
      end

      def exists?
        File.exists?(file_path)
      end
    end

    attr_reader :rc
    def initialize
      @rc = self.class.load
    end

    def accounts
      @accounts ||= rc.keys.map do |attributes|
        Account.new(attributes)
      end
    end

    class Account
      attr_reader :username, :consumer_key, :consumer_secret, :access_token, :access_token_secret
    end
  end
end