# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twurl/version'

Gem::Specification.new do |spec|
  spec.add_dependency 'oauth', '~> 0.4'
  spec.authors = ["Marcel Molina", "Erik Michaels-Ober", "@TwitterDev team"]
  spec.description = %q{Curl for the Twitter API}
  spec.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.extra_rdoc_files = %w(CODE_OF_CONDUCT.md CONTRIBUTING.md INSTALL.md LICENSE README.md)
  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.start_with?('test/') }
  spec.homepage = 'http://github.com/twitter/twurl'
  spec.licenses = ['MIT']
  spec.name = 'twurl'
  spec.rdoc_options = ['--title', 'twurl -- OAuth-enabled curl for the Twitter API', '--main', 'README.md', '--line-numbers', '--inline-source']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.4.0'
  spec.rubyforge_project = 'twurl'
  spec.summary = spec.description
  spec.version = Twurl::Version
end
