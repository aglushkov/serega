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

# ORM plugins
ruby_version = Gem::Version.new(RUBY_VERSION)
ar_version =
  if ruby_version >= Gem::Version.new("3.0")
    "~> 7.0"
  elsif ruby_version >= Gem::Version.new("2.5")
    "~> 6.0"
  else
    "~> 5.2"
  end

gem "activerecord", ar_version
gem "sqlite3", platforms: [:ruby]
gem "activerecord-jdbcsqlite3-adapter", platforms: [:jruby]
