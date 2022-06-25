# frozen_string_literal: true

require "support/activerecord"

load_plugin_code :activerecord_preloads

RSpec.describe Serega::Plugins::ActiverecordPreloads do
  describe described_class::Preloader do
    let(:plugin) { Serega::Plugins::ActiverecordPreloads }

    describe ".handlers" do
      it "returns memorized array of handlers" do
        expect(described_class.handlers).to eq [
          plugin::ActiverecordRelation,
          plugin::ActiverecordObject,
          plugin::ActiverecordArray
        ]

        expect(described_class.handlers).to be described_class.handlers
      end
    end

    describe ".preload" do
      it "raises error when can't find appropriate handler" do
        preloads = {}

        object = nil
        expect { described_class.preload(object, {}) }
          .to raise_error Serega::Error, "Can't preload #{preloads.inspect} to #{object.inspect}"

        object = []
        expect { described_class.preload(object, {}) }
          .to raise_error Serega::Error, "Can't preload #{preloads.inspect} to #{object.inspect}"

        object = 123
        expect { described_class.preload(object, {}) }
          .to raise_error Serega::Error, "Can't preload #{preloads.inspect} to #{object.inspect}"

        object = [AR::User.create!, AR::Comment.create!]
        expect { described_class.preload(object, {}) }
          .to raise_error Serega::Error, "Can't preload #{preloads.inspect} to #{object.inspect}"
      end

      it "preloads data to activerecord object" do
        user = AR::User.create!

        result = described_class.preload(user, {comments: {}})

        expect(result).to be user
        expect(user.association(:comments).loaded?).to be true
      end

      it "preloads data to activerecord array" do
        user = AR::User.create!

        users = [user]
        result = described_class.preload(users, {comments: {}})

        expect(result).to be users
        expect(result[0].association(:comments).loaded?).to be true
      end

      it "preloads data to activerecord relation" do
        user = AR::User.create!

        result = described_class.preload(AR::User.where(id: user.id), {comments: {}})

        expect(result).to eq [user]
        expect(result[0].association(:comments).loaded?).to be true
      end

      it "preloads data to loaded activerecord relation" do
        user = AR::User.create!

        result = described_class.preload(AR::User.where(id: user.id).load, {comments: {}})

        expect(result).to eq [user]
        expect(result[0].association(:comments).loaded?).to be true
      end
    end
  end
end
