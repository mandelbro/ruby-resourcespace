# frozen_string_literal: true

require_relative "lib/resourcespace/version"

Gem::Specification.new do |spec|
  spec.name          = "resourcespace-ruby"
  spec.version       = ResourceSpace::VERSION
  spec.authors       = ["Survey Flunkie Team"]
  spec.email         = ["info@surveyflunkie.com"]

  spec.summary       = "Ruby client for ResourceSpace Digital Asset Management API"
  spec.description   = "A comprehensive Ruby client library for interacting with ResourceSpace open-source Digital Asset Management system. Supports resource management, file uploads, searching, collections, and metadata operations."
  spec.homepage      = "https://github.com/survey-flunkie/resourcespace-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/survey-flunkie/resourcespace-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/survey-flunkie/resourcespace-ruby/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/resourcespace-ruby"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.7"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "mime-types", "~> 3.4"
  spec.add_dependency "json", "~> 2.6"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "vcr", "~> 6.1"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
  spec.add_development_dependency "yard", "~> 0.9"
end
