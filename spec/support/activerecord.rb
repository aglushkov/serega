# frozen_string_literal: true

require "active_record"

conn = ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:").connection

conn.create_table(:users) do |t|
  t.string :name
end

conn.create_table(:comments) do |t|
  t.belongs_to :user, index: false
  t.text :text
end

module AR
  class User < ActiveRecord::Base
    has_many :comments
  end

  class Comment < ActiveRecord::Base
    belongs_to :user
  end
end
