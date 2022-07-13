# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[spec standard]

desc "Run all examples scripts (check they work without raising errors)"
task :examples do
  Dir["examples/*.rb"].each do |file|
    `ruby '#{file}'`
  end
end
