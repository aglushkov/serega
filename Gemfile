# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in serega.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"

gem "standard", "~> 1.3"

gem "simplecov", "~> 0.21"

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1")
  gem "debug", ">= 1.0.0"
else
  gem "pry-byebug", "~> 3.9"
end

gem "debug", ">= 1.0.0" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1")
