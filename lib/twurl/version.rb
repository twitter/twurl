module Twurl
  class Version
    MAJOR = 0 unless defined? Twurl::Version::MAJOR
    MINOR = 9 unless defined? Twurl::Version::MINOR
    PATCH = 3 unless defined? Twurl::Version::PATCH
    PRE = nil unless defined? Twurl::Version::PRE # Time.now.to_i.to_s

    class << self
      # @return [String]
      def to_s
        [MAJOR, MINOR, PATCH, PRE].compact.join('.')
      end
    end
  end

  VERSION = Version.to_s
end
