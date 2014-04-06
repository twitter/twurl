module Twurl
  class Version
    MAJOR = 0 unless defined? Twurl::Version::MAJOR
    MINOR = 9 unless defined? Twurl::Version::MINOR
    PATCH = 2 unless defined? Twurl::Version::PATCH
    BETA = nil unless defined? Twurl::Version::BETA # Time.now.to_i.to_s

    class << self
      # @return [String]
      def to_s
        [MAJOR, MINOR, PATCH, BETA].compact.join('.')
      end
    end
  end

  VERSION = Version.to_s
end
