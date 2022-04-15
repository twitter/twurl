lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'twurl/version'

Gem::Specification.new do |spec|
  spec.add_dependency 'oauth', '~> 0.4'
  spec.add_dependency 'ostruct', '>= 0.3.3'
  spec.authors = ["Marcel Molina", "Erik Michaels-Ober", "@TwitterDev team"]
  spec.description = %q{Curl for the Twitter API}
  spec.bindir = 'bin'
  spec.executables << 'twurl'
  spec.extra_rdoc_files = Dir["*.md", "LICENSE"]
  spec.files = Dir["*.md", "LICENSE", "twurl.gemspec", "bin/*", "lib/**/*"]
  spec.homepage = 'https://github.com/twitter/twurl'
  spec.licenses = ['MIT']
  spec.name = 'twurl'
  spec.rdoc_options = ['--title', 'twurl -- OAuth-enabled curl for the Twitter API', '--main', 'README.md', '--line-numbers', '--inline-source']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.0'
  spec.summary = spec.description
  spec.version = Twurl::Version
end
