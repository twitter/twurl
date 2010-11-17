require 'rubygems'
require 'oauth'
require 'optparse'
require 'ostruct'
require 'stringio'
require 'yaml'

library_files = Dir[File.join(File.dirname(__FILE__), "/twurl/**/*.rb")].sort
library_files.each do |file|
  require file
end

module Twurl
  @options ||= Options.new
  class << self
    attr_accessor :options
  end

  class Exception < ::Exception
  end
end
