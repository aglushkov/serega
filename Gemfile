# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in serega.gemspec
gemspec

gem "rake", "~> 13.0"
gem "rspec", "~> 3.0", require: false
gem "standard", "~> 1.3", require: false
gem "simplecov", "~> 0.21", require: false
gem "rubocop-rake", "~> 0.6.0", require: false
gem "rubocop-rspec", "~> 2.11", ">= 2.11.1", require: false
gem "rubocop-performance", "~> 1.20", require: false
gem "redcarpet", "~> 3.5", require: false
gem "rspec-sqlimit", "~> 0.0.5", require: false
# Can be used in test like:
#  require 'allocation_stats'
#
#  stats = AllocationStats.trace do
#    subject
#  end
#
#  puts stats.allocations(alias_paths: true).group_by(:sourcefile, :sourceline).to_text
#
gem "allocation_stats", require: false
gem "yard", require: false
gem "mdl", "~> 0.13.0", require: false

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1")
  gem "debug", ">= 1.0.0"
else
  gem "pry-byebug", "~> 3.9"
end

# ORM plugins
ruby_version = Gem::Version.new(RUBY_VERSION)
ar_version =
  if ruby_version >= Gem::Version.new("3.0")
    "~> 7.1"
  elsif ruby_version >= Gem::Version.new("2.5")
    "~> 6.1"
  else
    "~> 5.2"
  end

gem "activerecord", ar_version
gem "sqlite3", platforms: [:ruby]
gem "activerecord-jdbcsqlite3-adapter", platforms: [:jruby]
