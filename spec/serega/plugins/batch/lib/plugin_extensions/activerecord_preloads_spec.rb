# frozen_string_literal: true

require "support/activerecord"
require "rspec-sqlimit"

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch do
  let(:serializer) { Class.new(Serega) { plugin :batch } }

  let(:base_serializer) do
    Class.new(Serega) do
      plugin :preloads
      plugin :activerecord_preloads
      plugin :batch
    end
  end

  before do
    user = AR::User.create!(first_name: "Bruce", last_name: "Wayne")

    post1 = AR::Post.create!(user: user, text: "post1")
    post2 = AR::Post.create!(user: user, text: "post2")

    AR::Comment.create!(post: post1, text: "comment1")
    AR::Comment.create!(post: post1, text: "comment2")
    AR::Comment.create!(post: post2, text: "comment3")
  end

  def groups(values, by:)
    values.each_with_object({}) do |element, groups|
      key = element.public_send(by)

      if groups.has_key?(key)
        groups[key] << element
      else
        groups[key] = [element]
      end
    end
  end

  context "when batch loaded records preload other records" do
    let(:user_serializer) do
      p_serializer = post_serializer
      groups = method(:groups)
      Class.new(base_serializer) do
        config.batch.define(:sorted_posts) do |ids|
          groups.call(AR::Post.where(user_id: ids).order(:text), by: :user_id)
        end

        attribute :first_name
        attribute :last_name
        attribute :posts, serializer: p_serializer, batch: {key: :id, loader: :sorted_posts}
      end
    end

    let(:post_serializer) do
      c_serializer = comment_serializer
      Class.new(base_serializer) do
        attribute :text
        attribute :comments, serializer: c_serializer, preload: :comments
      end
    end

    let(:comment_serializer) do
      Class.new(base_serializer) do
        attribute :text
      end
    end

    it "preloads data to batch loaded records", :with_rollback do
      users = AR::User.all

      result = nil
      expect { result = user_serializer.to_h(users) }.not_to exceed_query_limit(3)

      expect(result.count).to eq 1 # 1 user
      expect(result[0][:posts].count).to eq 2 # 2 posts
      expect(result[0][:posts][0][:comments].count).to eq 2 # 2 comments of post1
      expect(result[0][:posts][1][:comments].count).to eq 1 # 1 comment of post2
    end
  end

  context "with batch loaded static data" do
    let(:user_serializer) do
      Class.new(base_serializer) do
        config.batch.define(:posts_count) do |ids|
          AR::Post.where(user_id: ids).group(:user_id).count
        end

        config.batch.define(:comments_count) do |ids|
          AR::Comment.joins(:post).where(posts: {user_id: ids}).group(:user_id).count
        end

        attribute :first_name
        attribute :last_name
        attribute :posts_count, batch: {key: :id, loader: :posts_count}
        attribute :comments_count, batch: {key: :id, loader: :comments_count}
      end
    end

    it "preloads data correctly", :with_rollback do
      users = AR::User.all

      result = nil
      expect { result = user_serializer.to_h(users) }.not_to exceed_query_limit(3)

      expect(result[0][:posts_count]).to eq 2
      expect(result[0][:comments_count]).to eq 3
    end
  end

  context "when batch loaded records also load other records using batch" do
    let(:user_serializer) do
      p_serializer = post_serializer
      groups = method(:groups)
      Class.new(base_serializer) do
        config.batch.define(:sorted_posts) do |ids|
          groups.call(AR::Post.where(user_id: ids).order(:text), by: :user_id)
        end

        attribute :first_name
        attribute :last_name
        attribute :posts, serializer: p_serializer, batch: {key: :id, loader: :sorted_posts}
      end
    end

    let(:post_serializer) do
      c_serializer = comment_serializer
      groups = method(:groups)
      Class.new(base_serializer) do
        config.batch.define(:sorted_comments) do |ids|
          groups.call(AR::Comment.where(post_id: ids).order(:text), by: :post_id)
        end

        attribute :text
        attribute :comments, serializer: c_serializer, batch: {key: :id, loader: :sorted_comments}
      end
    end

    let(:comment_serializer) do
      Class.new(base_serializer) do
        attribute :text
      end
    end

    it "preloads data to batch loaded records", :with_rollback do
      users = AR::User.all

      result = nil
      expect { result = user_serializer.to_h(users) }.not_to exceed_query_limit(3)

      expect(result.count).to eq 1 # 1 user
      expect(result[0][:posts].count).to eq 2 # 2 posts
      expect(result[0][:posts][0][:comments].count).to eq 2 # 2 comments of post1
      expect(result[0][:posts][1][:comments].count).to eq 1 # 1 comment of post2
    end
  end
end
