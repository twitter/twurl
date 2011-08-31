#!/usr/bin/env rake
require 'rake/testtask'
require 'rubygems/package_task'

task :default => :test

Rake::TestTask.new do |test|
  test.pattern = 'test/*_test.rb'
  test.verbose = true
end

namespace :dist do
  spec = Gem::Specification.load('twurl.gemspec')

  Gem::PackageTask.new(spec) do |pkg|
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
