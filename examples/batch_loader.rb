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

def groups(keys, values, by:, default: nil)
  data =
    values.each_with_object({}) do |element, groups|
      key = element.public_send(by)

      if groups.has_key?(key)
        groups[key] << element
      else
        groups[key] = [element]
      end
    end

  keys.each { |key| data[key] ||= default }
  data
end

# Serializers
class SimpleSerializer < Serega
  plugin :batch
end

class UserSerializer < SimpleSerializer
  attribute :first_name
  attribute :last_name
  attribute :posts, serializer: "PostSerializer", many: true, batch: {key: :id, loader: :users_posts}

  config.batch_loaders.define(:users_posts) do |ids|
    Post.where(user_id: ids).each_with_object({}) do |post, groups|
      key = post.user_id

      if groups.has_key?(key)
        groups[key] << post
      else
        groups[key] = [post]
      end
    end
  end
end

class PostSerializer < SimpleSerializer
  attribute :text
  attribute :comments, serializer: "CommentSerializer", many: true, batch: {key: :id, loader: :posts_comments}

  config.batch_loaders.define(:posts_comments) do |ids|
    Comment.where(post_id: ids).each_with_object({}) do |comment, groups|
      key = comment.post_id

      if groups.has_key?(key)
        groups[key] << comment
      else
        groups[key] = [comment]
      end
    end
  end
end

class CommentSerializer < SimpleSerializer
  attribute :text
end

# We need to show just DB queries in this examples to show we have no N+1
allow_db_logs =
  Module.new do
    def to_h(*)
      old_level = ActiveRecord::Base.logger.level
      ActiveRecord::Base.logger.level = Logger::DEBUG
      super
    ensure
      ActiveRecord::Base.logger.level = old_level
    end
  end

UserSerializer.include(allow_db_logs)

def example(message)
  puts
  puts "----------------"
  puts
  puts message
  puts
  yield
end

example("Single object:") do
  UserSerializer.new.to_h(user1)
end

example("Array:") do
  users = [user1, user2, user3]
  UserSerializer.new.to_h(users)
end

example("Relation:") do
  users = User.all
  puts UserSerializer.new.to_h(users).inspect
end
