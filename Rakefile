require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/gempackagetask'

require File.dirname(__FILE__) + '/lib/twurl'

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

namespace :dist do
  spec = Gem::Specification.new do |s|
    s.name              = 'twurl'
    s.version           = Gem::Version.new(Twurl::Version)
    s.summary           = "Curl for the Twitter API"
    s.description       = s.summary
    s.email             = ['marcel@twitter.com', 'raffi@twitter.com']
    s.authors           = ['Marcel Molina', 'Raffi Krikorian']
    s.has_rdoc          = true
    s.extra_rdoc_files  = %w(README COPYING INSTALL)
    s.homepage          = 'http://github.com/marcel/twurl'
    s.rubyforge_project = 'twurl'
    s.files             = FileList['Rakefile', 'lib/**/*.rb', 'bin/*']
    s.executables       << 'twurl'
    s.test_files        = Dir['test/**/*']

    s.add_dependency 'oauth'
    s.rdoc_options  = ['--title', "twurl -- OAuth-enabled curl for the Twitter API",
                       '--main',  'README',
                       '--line-numbers', '--inline-source']
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar_gz = true
    pkg.package_files.include('{lib,bin,test}/**/*')
    pkg.package_files.include('README')
    pkg.package_files.include('COPYING')
    pkg.package_files.include('INSTALL')
    pkg.package_files.include('Rakefile')
  end

  task :spec do
    puts spec.to_ruby
  end

  desc "Unpack current version of library into the twitter.com vendor directory"
  task :unpack_to_vendor => :repackage do
    cd 'pkg'
    system("gem unpack '#{spec.name}-#{spec.version}.gem' --target=$TWITTER/vendor/gems")
  end
end