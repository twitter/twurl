require 'rubygems'
require 'rake'
require 'rake/testtask'

library_root = File.dirname(__FILE__)

task :default => :test

Rake::TestTask.new do |test|
  test.pattern = 'test/*_test.rb'
  test.verbose = true
end

namespace :test do
  desc "Analyze test coverage"
  task :coverage do
    system("rcov -x Library -x support --sort coverage #{File.join(library_root, 'test/*_test.rb')}")
    system("open #{File.join(library_root, 'coverage/index.html')}") if PLATFORM['darwin']
  end

  namespace :coverage do
    desc "Remove artifacts generated from coverage analysis"
    task :clobber do
      rm_r 'coverage' rescue nil
    end
  end
end