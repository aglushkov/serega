# frozen_string_literal: true

require_relative "lib/serega/version"

Gem::Specification.new do |spec|
  spec.name = "serega"
  spec.version = Serega::VERSION
  spec.authors = ["Andrey Glushkov"]
  spec.email = ["aglushkov@shakuro.com"]

  spec.summary = "JSON Serializer for REST API"
  spec.description = <<~DESC
    - Simple and clear DSL
    - Ability to manually select serialized fields
    - Multiple ways to solve N+1 problems
    - Built-in presenter
    - No dependencies
    - Plugin system as in Roda or Shrine
  DESC
  spec.homepage = "https://github.com/aglushkov/serega"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aglushkov/serega"
  spec.metadata["changelog_uri"] = "https://github.com/aglushkov/serega/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir["lib/**/*.rb"] << "VERSION"
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
