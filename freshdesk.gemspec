# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'freshdesk/version'

Gem::Specification.new do |spec|
  spec.name          = "freshdesk"
  spec.version       = Freshdesk::VERSION
  spec.authors       = ["Brent Mulligan"]
  spec.email         = ["brent@bmemedia.net"]
  spec.description   = 'Freshdesk JSON API client for Ruby'
  spec.summary       = 'Freshdesk JSON API client for Ruby'
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency('rest-client', '~> 1.4')
  spec.add_dependency('mime-types', '~> 1.25')
  spec.add_dependency('json', '~> 1.8.1')

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
