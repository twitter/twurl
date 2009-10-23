$:.unshift File.dirname(__FILE__) + '/../lib'
require 'twurl'
require 'test/unit'
require 'rr'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end

Twurl::RCFile.directory = ENV['TMPDIR']
