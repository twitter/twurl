module Twurl
  class RCFile
    FILE = '.twurlrc'
    class << self
      def directory
        @@directory ||= File.expand_path('~')
      end

      def directory=(dir)
        @@directory = dir
      end

      def file_path
        File.join(directory, FILE)
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
      File.open(self.class.file_path, File::RDWR|File::CREAT|File::TRUNC, 0600) do |rcfile|
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

    def default_profile_consumer_key
      username, consumer_key = configuration['default_profile']
      consumer_key
    end

    def default_profile=(profile)
      configuration['default_profile'] = [profile.username, profile.consumer_key]
    end

    def configuration
      data['configuration']
    end

    def alias(name, path)
      data['aliases'] ||= {}
      data['aliases'][name] = path
      save
    end

    def aliases
      data['aliases'] ||= {}
    end

    def bearer_token(consumer_key, bearer_token)
      data['bearer_tokens'] ||= {}
      data['bearer_tokens'][consumer_key] = bearer_token
      save
    end

    def bearer_tokens
      data['bearer_tokens']
    end

    def alias_from_options(options)
      options.subcommands.each do |potential_alias|
        if path = alias_from_name(potential_alias)
          break path
        end
      end
    end

    def alias_from_name(name)
      aliases[name]
    end

    def has_oauth_profile_for_username_with_consumer_key?(username, consumer_key)
      user_profiles = self[username]
      !user_profiles.nil? && !user_profiles[consumer_key].nil?
    end

    def has_bearer_token_for_consumer_key?(consumer_key)
      bearer_tokens.nil? ? false : bearer_tokens.to_hash.has_key?(consumer_key)
    end

    def <<(oauth_client)
      client_from_file = self[oauth_client.username] || {}
      client_from_file[oauth_client.consumer_key] = oauth_client.to_hash
      (profiles[oauth_client.username] ||= {}).update(client_from_file)
      self.default_profile = oauth_client unless default_profile
      save
    end
  end
end
