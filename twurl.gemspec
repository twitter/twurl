# encoding: utf-8
require File.expand_path('../lib/twurl/version', __FILE__)

Gem::Specification.new do |spec|
  spec.add_dependency 'oauth', '~> 0.4'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rr'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'minitest'
  spec.authors = ["Marcel Molina", "Erik Michaels-Ober"]
  spec.description = %q{Curl for the Twitter API}
  spec.email = ['marcel@twitter.com']
  spec.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.extra_rdoc_files = %w(COPYING INSTALL README)
  spec.files = `git ls-files`.split("\n")
  spec.homepage = 'http://github.com/marcel/twurl'
  spec.licenses = ['MIT']
  spec.name = 'twurl'
  spec.rdoc_options = ['--title', 'twurl -- OAuth-enabled curl for the Twitter API', '--main', 'README', '--line-numbers', '--inline-source']
  spec.require_paths = ['lib']
  spec.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')
  spec.rubyforge_project = 'twurl'
  spec.summary = spec.description
  spec.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.version = Twurl::Version
end
