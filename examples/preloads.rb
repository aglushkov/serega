# frozen_string_literal: true

version = File.read(File.join(File.dirname(__FILE__), "../VERSION")).strip
local_file = File.join(File.dirname(__FILE__), "../serega-#{version}.gem")
local_file_exist = File.file?(local_file)

require "bundler/inline"

gemfile(true, quiet: true) do
  source "https://rubygems.org"
  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "serega", "~> #{version}", local_file_exist ? {path: File.dirname(local_file)} : {}
  gem "sqlite3"
  gem "activerecord"
end

class AppSerializer < Serega
end

require "active_record"
require "logger"

logger = Logger.new($stdout)
logger.level = Logger::INFO
logger.formatter = proc { |severity, datetime, progname, msg| msg << "\n" }
ActiveRecord::Base.logger = logger
ActiveSupport::LogSubscriber.colorize_logging = false
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

# Schema (user has many posts, post has many comments)
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :first_name
    t.string :last_name
  end

  create_table :posts, force: true do |t|
    t.integer :user_id
    t.string :text
  end

  create_table :comments, force: true do |t|
    t.integer :post_id
    t.integer :user_id
    t.string :text
  end
end

# Models
class User < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  belongs_to :user, optional: true
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :post, optional: true
  belongs_to :user, optional: true
end

# Data
user1 = User.create!(first_name: "Bruce", last_name: "Wayne")
user2 = User.create!(first_name: "Clark", last_name: "Kent")
user3 = User.create!(first_name: "Jane", last_name: "Doe")

post1 = Post.create!(user: user1, text: "post1")
post2 = Post.create!(user: user1, text: "post2")

Comment.create!(user: user1, post: post1, text: "comment1")
Comment.create!(user: user2, post: post1, text: "comment2")
Comment.create!(user: user3, post: post2, text: "comment3")
Comment.create!(user: user1, post: post2, text: "comment4")

# Serializers
class AppSerializer < Serega
  plugin :preloads
  plugin :activerecord_preloads,
    auto_preload_attributes_with_serializer: true,
    auto_preload_attributes_with_delegate: true,
    auto_hide_attributes_with_preload: false
end

class UserSerializer < AppSerializer
  attribute :first_name
  attribute :last_name
  attribute :posts, serializer: -> { PostSerializer }
end

class PostSerializer < AppSerializer
  attribute :text
  attribute :comments, serializer: -> { CommentSerializer }
end

class CommentSerializer < AppSerializer
  attribute :text
  # attribute :user, serializer: -> { UserSerializer }
end

# We need to show just DB queries in this examples to show we have no N+1
LogQueries =
  Module.new do
    def serialize(*)
      ActiveRecord::Base.logger.level = Logger::DEBUG
      super
    ensure
      ActiveRecord::Base.logger.level = Logger::INFO
    end
  end

UserSerializer.include(LogQueries)
CommentSerializer.include(LogQueries)

def example(message)
  puts
  puts "----------------"
  puts
  puts message
  puts
  yield
end

example("Single object:") do
  UserSerializer.new.call(user1.reload)
end

example("Single object with created post:") do
  user1.reload
  user1.posts.create!(text: "post3")

  UserSerializer.new.to_h(user1)
end

example("Array:") do
  users = [user1.reload, user2.reload, user3.reload]
  UserSerializer.new.to_h(users)
end

example("Array with created posts in some user:") do
  users = [user1.reload, user2.reload, user3.reload]
  user1.posts.create!(text: "post4")

  UserSerializer.new.to_h(users)
end

example("Relation:") do
  users = User.all
  UserSerializer.new.to_h(users)
end

example("Loaded Relation:") do
  users = User.all.load
  UserSerializer.new.to_h(users)
end

example("Relation included posts:") do
  users = User.all.includes(:posts)
  UserSerializer.new.to_h(users)
end

example("Loaded attribute included posts:") do
  users = User.all.includes(:posts).load
  UserSerializer.new.to_h(users)
end

example("No preloads:") do
  comments = Comment.all
  CommentSerializer.to_h(comments)
end
