# frozen_string_literal: true

if RUBY_ENGINE == "ruby" && (ARGV.none? || ARGV == ["spec"] || ARGV == ["spec/"])
  require "simplecov"
  SimpleCov.start
end

unless ENV["CI"]
  begin
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1.0")
      require "debug"
    else
      require "pry-byebug"
    end
  rescue LoadError
  end
end

require "serega"

def load_plugin_code(name)
  ser = Class.new(Serega)
  ser.plugin(name)
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
