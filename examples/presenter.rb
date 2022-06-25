# frozen_string_literal: true

version = File.read(File.join(File.dirname(__FILE__), "../VERSION")).strip
local_file = File.join(File.dirname(__FILE__), "../serega-#{version}.gem")
local_file_exist = File.file?(local_file)

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "serega", "~> #{version}", local_file_exist ? {path: File.dirname(local_file)} : {}
end

class AppSerializer < Serega
  plugin :presenter
end

class UserSerializer < AppSerializer
  attribute :id
  attribute :name
  relation :profile, serializer: "ProfileSerializer"

  class Presenter
    def name
      [first_name, last_name].join(" ")
    end
  end
end

class ProfileSerializer < AppSerializer
  attribute :id
  attribute :location
  attribute :followers_count

  class Presenter
    def location
      "Gotham City"
    end
  end
end

require "ostruct"
profile = OpenStruct.new(id: 2, followers_count: 999, location: "Earth")
user = OpenStruct.new(id: 1, first_name: "Clark", last_name: "Kent", profile: profile)

response = UserSerializer.new.to_h(user)

require "json"
puts JSON.pretty_generate(response)
