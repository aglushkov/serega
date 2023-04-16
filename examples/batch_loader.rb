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

# Schema (user has many posts, post has many comments, comment has many views)
ActiveRecord::Migration.verbose = false
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

  create_table :views, force: true do |t|
    t.integer :comment_id
    t.integer :count
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
  has_one :view
end

class View < ActiveRecord::Base
  belongs_to :comment, optional: true
end

# Data
user1 = User.create!(first_name: "Bruce", last_name: "Wayne")
user2 = User.create!(first_name: "Clark", last_name: "Kent")
user3 = User.create!(first_name: "Jane", last_name: "Doe")

post1 = Post.create!(user: user1, text: "post1")
post2 = Post.create!(user: user1, text: "post2")

comment1 = Comment.create!(user: user1, post: post1, text: "comment1")
comment2 = Comment.create!(user: user2, post: post1, text: "comment2")
comment3 = Comment.create!(user: user3, post: post2, text: "comment3")
comment4 = Comment.create!(user: user1, post: post2, text: "comment4")

View.create!(comment: comment1, count: 1)
View.create!(comment: comment2, count: 2)
View.create!(comment: comment3, count: 3)
View.create!(comment: comment4, count: 4)

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
class AppSerializer < Serega
  plugin :preloads,
    auto_preload_attributes_with_serializer: true,
    auto_preload_attributes_with_delegate: true,
    auto_hide_attributes_with_preload: false

  plugin :activerecord_preloads
  plugin :batch
end

class UserSerializer < AppSerializer
  attribute :first_name
  attribute :last_name
  attribute :posts, serializer: "PostSerializer", many: true, batch: {key: :id, loader: :users_posts}

  config.batch.define(:users_posts) do |ids|
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

class PostSerializer < AppSerializer
  attribute :text
  attribute :comments, serializer: "CommentSerializer", many: true, batch: {key: :id, loader: :posts_comments}

  config.batch.define(:posts_comments) do |ids, _ctx, point|
    scope = Comment.preload(point.preloads)
    scope = scope.where(post_id: ids)
    scope.each_with_object({}) do |comment, groups|
      key = comment.post_id

      if groups.has_key?(key)
        groups[key] << comment
      else
        groups[key] = [comment]
      end
    end
  end
end

class CommentSerializer < AppSerializer
  attribute :text
  attribute :views_count, delegate: {to: :view, key: :count}, preload: :view
end

def example(message, expected_queries_count:)
  sqls = Storage.sqls
  sqls.clear

  yield

  if sqls.count != expected_queries_count
    raise "#{message}: expected #{expected_queries_count}, but there were #{sqls.count} requests: \n - #{sqls.join("\n - ")}"
  end
end

class Storage
  @sqls = []

  class << self
    attr_accessor :sqls
  end
end

ActiveSupport::Notifications.subscribe "sql.active_record" do |_name, _started, _finished, _id, payload|
  Storage.sqls << payload[:sql]
end

example("Single object", expected_queries_count: 3) do
  UserSerializer.new.to_h(user1)
end

example("Array", expected_queries_count: 3) do
  users = [user1, user2, user3]
  UserSerializer.new.to_h(users)
end

example("Relation", expected_queries_count: 4) do
  users = User.all
  UserSerializer.new.to_h(users).inspect
end
