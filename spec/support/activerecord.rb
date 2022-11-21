# frozen_string_literal: true

require "active_record"

conn = ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:").connection

conn.create_table(:users) do |t|
  t.string :first_name
  t.string :last_name
end

conn.create_table(:posts) do |t|
  t.belongs_to :user, index: false
  t.string :text
end

conn.create_table(:comments) do |t|
  t.belongs_to :post, index: false
  t.string :text
end

module AR
  class User < ActiveRecord::Base
    has_many :posts
  end

  class Post < ActiveRecord::Base
    belongs_to :user
    has_many :comments
  end

  class Comment < ActiveRecord::Base
    belongs_to :post
  end
end

RSpec.configure do |config|
  config.around :each, :with_rollback do |example|
    ActiveRecord::Base.transaction do
      example.run
    ensure
      raise ActiveRecord::Rollback
    end
  end
end
