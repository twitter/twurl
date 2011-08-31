# encoding: utf-8
require File.expand_path('../lib/twurl/version', __FILE__)

Gem::Specification.new do |s|
  s.add_dependency 'oauth', '~> 0.4'
  s.add_development_dependency 'rake', '~> 0.8'
  s.add_development_dependency 'rr', '~> 1.0'
  s.add_development_dependency 'test-unit', '~> 2.1'
  s.authors = ["Marcel Molina", "Raffi Krikorian"]
  s.description = %q{Curl for the Twitter API}
  s.email = ['marcel@twitter.com', 'raffi@twitter.com']
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = %w(CHANGELOG COPYING INSTALL README)
  s.files = `git ls-files`.split("\n")
  s.homepage = 'http://github.com/marcel/twurl'
  s.name = 'twurl'
  s.rdoc_options = ['--title', 'twurl -- OAuth-enabled curl for the Twitter API', '--main', 'README', '--line-numbers', '--inline-source']
  s.require_paths = ['lib']
  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.6') if s.respond_to? :required_rubygems_version=
  s.rubyforge_project = 'twurl'
  s.summary = s.description
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.version = Twurl::Version
end
