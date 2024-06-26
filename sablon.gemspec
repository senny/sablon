# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sablon/version'

Gem::Specification.new do |spec|
  spec.name          = "sablon"
  spec.version       = Sablon::VERSION
  spec.authors       = ["Yves Senn"]
  spec.email         = ["yves.senn@gmail.com"]
  spec.summary       = %q{docx template processor}
  spec.description   = %q{Sablon is a document template processor. At this time it works only with docx and MailMerge fields.}
  spec.homepage      = "http://github.com/senny/sablon"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_runtime_dependency 'nokogiri', ">= 1.8.5"
  spec.add_runtime_dependency 'rubyzip', ">= 1.3.0"

  spec.add_development_dependency "bundler", ">= 1.6"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.4"
  spec.add_development_dependency "xml-simple"
  spec.add_development_dependency "ostruct"
end
