# frozen_string_literal: true

require_relative "lib/michel/version"

Gem::Specification.new do |spec|
  spec.name = "michel"
  spec.version = Michel::VERSION
  spec.authors = ["Sally Hall", "Aji Slater"]
  spec.email = ["sally@thoughtbot.com", "aji.slater@gmail.com"]

  spec.summary = "Generator to help with appointment scheduling"
  spec.homepage = "https://github.com/thoughtbot/michel/"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.

  spec.files = `git ls-files`.split("\n")
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activerecord", ">= 7.0.0"
  spec.add_dependency "pg", "~> 1.0"
  spec.add_dependency "scenic", "~>1.9"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
