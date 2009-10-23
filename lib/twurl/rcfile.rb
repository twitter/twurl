module Twurl
  class RCFile
    FILE = '.twurlrc'
    @home_directory ||= ENV['HOME']
    class << self
      attr_accessor :home_directory

      def file_path
        File.join(home_directory, FILE)
      end

      def load
        YAML.load_file(file_path)
      rescue Errno::ENOENT
        default_rcfile_structure
      end

      def default_rcfile_structure
        {'profiles' => {}, 'configuration' => {}}
      end
    end

    attr_reader :data
    def initialize
      @data = self.class.load
    end
    
    def empty?
      data == self.class.default_rcfile_structure
    end

    def save
      File.open(self.class.file_path, 'w') do |rcfile|
        rcfile.write data.to_yaml
      end
    end

    def [](username)
      profiles[username]
    end

    def profiles
      data['profiles']
    end

    def default_profile
      configuration['default_profile']
    end

    def default_profile=(profile)
      configuration['default_profile'] = profile.username
    end

    def configuration
      data['configuration']
    end

    def has_oauth_profile_for_username?(username)
      !self[username].nil?
    end

    def <<(oauth_client)
      client_from_file = self[oauth_client.username] || {}
      client_from_file.update(oauth_client.to_hash)
      profiles[oauth_client.username] = client_from_file
      self.default_profile = oauth_client unless default_profile
      save
    end
  end
end