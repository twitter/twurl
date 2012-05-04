module Twurl
  module VERSION
    MAJOR  = '0' unless defined? MAJOR
    MINOR  = '7' unless defined? MINOR
    PATCH  = '0' unless defined? PATCH
    BETA   = nil unless defined? BETA # Time.now.to_i.to_s
  end

  Version = [VERSION::MAJOR, VERSION::MINOR, VERSION::PATCH, VERSION::BETA].compact * '.'
end
