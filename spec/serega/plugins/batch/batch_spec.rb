# frozen_string_literal: true

require "support/activerecord"

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch do
  let(:serializer) { Class.new(Serega) { plugin :batch } }

  describe "loading" do
    it "adds allowed attribute options" do
      attribute_keys = serializer.config.attribute_keys
      expect(attribute_keys).to include :batch
    end
  end

  describe ".inherited" do
    let(:parent) { serializer }

    it "inherits SeregaBatchLoader and SeregaBatchLoaders classes" do
      child = Class.new(parent)
      expect(parent::SeregaBatchLoader).to be child::SeregaBatchLoader.superclass
      expect(parent::SeregaBatchLoaders).to be child::SeregaBatchLoaders.superclass
    end
  end

  describe "validations" do
    it "checks :batch_loader attribute option" do
      expect { serializer.attribute :foo, batch: true }.to raise_error Serega::SeregaError
      expect { serializer.attribute :foo, batch: {key: :key, loader: proc {}} }.not_to raise_error
    end
  end

  describe "Attribute methods" do
    specify "#batch" do
      batch_loader = proc { |_ids| }
      at1 = serializer.attribute :at1, batch: {key: :key, loader: batch_loader}
      at2 = serializer.attribute :at2

      expect(at1.batch).to eq({key: :key, loader: batch_loader})
      expect(at2.batch).to be_nil
    end
  end

  describe "BatchLoadersConfig" do
    let(:loaders_config) { Serega::SeregaPlugins::Batch::BatchLoadersConfig.new({}) }

    describe "#define" do
      it "defines named loader" do
        loader = proc {}
        loaders_config.define(:name, &loader)
        expect(loaders_config.opts).to eq(name: loader)
      end

      it "raises error when block not provided" do
        expect { loaders_config.define(:name) }.to raise_error Serega::SeregaError, "Block must be given to batch_loaders.define method"
      end

      it "raises error when provided incorrect params" do
        expect { loaders_config.define(:name) {} }.not_to raise_error
        expect { loaders_config.define(:name) { |a| } }.not_to raise_error
        expect { loaders_config.define(:name) { |a, b| } }.not_to raise_error
        expect { loaders_config.define(:name) { |a, b, c| } }.not_to raise_error
        expect { loaders_config.define(:name) { |a, b, c, d| } }.to raise_error "Block can have maximum 3 regular parameters"
        expect { loaders_config.define(:name) { |*a| } }.to raise_error "Block can have maximum 3 regular parameters"
        expect { loaders_config.define(:name) { |a: nil| } }.to raise_error "Block can have maximum 3 regular parameters"
      end
    end

    describe "#fetch" do
      it "returns defined loader by name" do
        loader = proc {}
        loaders_config.define(:name, &loader)
        expect(loaders_config.fetch(:name)).to eq loader
      end

      it "raises error when loader was not found" do
        expect { loaders_config.fetch(:name) }.to raise_error Serega::SeregaError,
          "Batch loader with name `:name` was not defined. Define example: config.batch_loaders.define(:name) { |keys, ctx, points| ... }"
      end
    end
  end

  describe "BatchModel" do
    describe "#loader" do
      it "returns provided Proc loader" do
        loader = proc {}
        opts = {loader: loader}
        model = Serega::SeregaPlugins::Batch::BatchModel.new(opts, nil, nil)

        expect(model.loader).to eq loader
      end

      it "returns loader found by Symbol name" do
        loader = proc {}
        opts = {loader: :loader_name}
        loaders = Serega::SeregaPlugins::Batch::BatchLoadersConfig.new(loader_name: loader)
        model = Serega::SeregaPlugins::Batch::BatchModel.new(opts, loaders, nil)

        expect(model.loader).to eq loader
      end
    end

    describe "#key" do
      it "returns provided Proc key" do
        key = proc {}
        opts = {key: key}
        model = Serega::SeregaPlugins::Batch::BatchModel.new(opts, nil, nil)

        expect(model.key).to eq key
      end

      it "constructs Proc with Symbol key" do
        opts = {key: :some_count}
        model = Serega::SeregaPlugins::Batch::BatchModel.new(opts, nil, nil)
        object = double(some_count: 3)

        expect(model.key.call(object)).to eq 3
      end
    end

    describe "#default_value" do
      it "returns nil by default" do
        model = Serega::SeregaPlugins::Batch::BatchModel.new({}, nil, nil)
        expect(model.default_value).to be_nil
      end

      it "returns provided default" do
        model = Serega::SeregaPlugins::Batch::BatchModel.new({default: 0}, nil, nil)
        expect(model.default_value).to eq 0
      end

      it "returns provided default when many=true" do
        model = Serega::SeregaPlugins::Batch::BatchModel.new({default: 0}, nil, true)
        expect(model.default_value).to eq 0
      end

      it "returns empty Array by default when many=true" do
        model = Serega::SeregaPlugins::Batch::BatchModel.new({}, nil, true)
        expect(model.default_value).to be Serega::FROZEN_EMPTY_ARRAY
      end
    end
  end

  describe "MapPoint methods" do
    specify "#batch" do
      batch_loader = proc {}
      at1 = serializer.attribute :at1, many: true, batch: {key: :key, loader: batch_loader}
      at2 = serializer.attribute :bar
      pt1 = serializer::SeregaMapPoint.new(at1, [])
      pt2 = serializer::SeregaMapPoint.new(at2, [])

      batch = pt1.batch
      expect(batch).to be_a Serega::SeregaPlugins::Batch::BatchModel
      expect(batch.many).to be true
      expect(batch.loaders).to be serializer.config.batch_loaders
      expect(batch.key).to be_a(Proc)
      expect(batch).to be pt1.batch # check stores value

      expect(pt2.batch).to be_nil
    end
  end

  describe "serialization" do
    subject(:result) { user_serializer.to_h(users) }

    context "when no batch loaded attributes" do
      let(:user_serializer) do
        Class.new(Serega) do
          plugin :batch
          attribute :first_name
        end
      end

      let(:users) { double(first_name: "USER") }

      it "does not raise errors" do
        expect(result).to eq({first_name: "USER"})
      end
    end

    context "with simple batch loaded value" do
      let(:user_serializer) do
        Class.new(Serega) do
          plugin :batch

          attribute :first_name
          attribute :online_time, batch: {key: :online_id, loader: proc { |_ids, _ctx, _points| {1 => 10, 2 => 20} }}
          attribute :offline_time, batch: {key: :offline_id, loader: proc { |_ids, _ctx, _points| {3 => 30, 4 => 40} }}
        end
      end

      let(:users) do
        [
          double(first_name: "USER1", online_id: 1, offline_id: 3),
          double(first_name: "USER2", online_id: 2, offline_id: 4),
          double(first_name: "USER3", online_id: 1, offline_id: 4)
        ]
      end

      it "returns correct response" do
        expect(result).to eq(
          [
            {first_name: "USER1", online_time: 10, offline_time: 30},
            {first_name: "USER2", online_time: 20, offline_time: 40},
            {first_name: "USER3", online_time: 10, offline_time: 40}
          ]
        )
      end
    end

    context "with not a resulted Hash batch loaded value" do
      let(:user_serializer) do
        Class.new(Serega) do
          plugin :batch
          attribute :online_time, batch: {key: :online_id, loader: proc { 1 }}
        end
      end

      let(:user) { double(first_name: "USER1", online_id: 1) }

      it "raises correct error" do
        expect { user_serializer.to_h(user) }
          .to raise_error Serega::SeregaError, "Batch loader for `#{user_serializer}.online_time` must return Hash, but #{1.inspect} was returned"
      end
    end

    context "with batch loaded relation" do
      let(:status_serializer) do
        Class.new(Serega) do
          attribute :text
        end
      end

      let(:user_serializer) do
        child_serializer = status_serializer
        all_statuses = statuses
        Class.new(Serega) do
          plugin :batch

          attribute :first_name
          attribute :status, serializer: child_serializer,
            batch: {key: :status_id, loader: proc { |ids, _ctx, _points| {1 => all_statuses[0], 2 => all_statuses[1]} }}
        end
      end

      let(:users) do
        [
          double(first_name: "USER1", status_id: 1),
          double(first_name: "USER2", status_id: 2)
        ]
      end

      let(:statuses) do
        [
          double(id: 1, text: "TEXT1"),
          double(id: 2, text: "TEXT2")
        ]
      end

      it "returns array with relations" do
        expect(result).to eq(
          [
            {first_name: "USER1", status: {text: "TEXT1"}},
            {first_name: "USER2", status: {text: "TEXT2"}}
          ]
        )
      end
    end

    context "with batch load inside batch_load" do
      let(:status_serializer) do
        Class.new(Serega) do
          plugin :batch
          attribute :name,
            batch: {key: :id, loader: proc { |ids, _ctx, _points| {1 => "draft", 2 => "published"} }}
        end
      end

      let(:post_serializer) do
        st_serializer = status_serializer
        all_statuses = statuses
        Class.new(Serega) do
          plugin :batch
          attribute :status, serializer: st_serializer,
            batch: {key: :status_id, loader: proc { |ids, _ctx, _points| {1 => all_statuses[0], 2 => all_statuses[1]} }}
        end
      end

      let(:user_serializer) do
        pst_serializer = post_serializer
        all_posts = posts
        Class.new(Serega) do
          plugin :batch
          attribute :first_name
          attribute :post,
            serializer: pst_serializer,
            batch: {key: :post_id, loader: proc { |ids, _ctx, _points| {1 => all_posts[0], 2 => all_posts[1]} }}
        end
      end

      let(:users) { [double(first_name: "USER1", post_id: 1), double(first_name: "USER2", post_id: 2)] }
      let(:posts) { [double(id: 1, status_id: 1), double(id: 2, status_id: 2)] }
      let(:statuses) { [double(id: 1), double(id: 2)] }

      it "returns array with deeply nested relations" do
        expect(result).to eq(
          [
            {first_name: "USER1", post: {status: {name: "draft"}}},
            {first_name: "USER2", post: {status: {name: "published"}}}
          ]
        )
      end
    end

    context "with formatters plugin" do
      let(:user_serializer) do
        Class.new(Serega) do
          plugin :formatters
          plugin :batch

          attribute :first_name

          attribute :post,
            batch: {key: :post_id, loader: proc { |ids, _ctx, _points| {123 => "123", 234 => "234"} }}

          attribute :post_reverse,
            batch: {key: :post_id, loader: proc { |ids, _ctx, _points| {123 => "123", 234 => "234"} }},
            format: proc { |value| value.reverse }
        end
      end

      let(:users) do
        [
          double(first_name: "USER1", post_id: 123),
          double(first_name: "USER2", post_id: 234)
        ]
      end

      it "returns correctly formatted batch_loaded data" do
        expect(result).to eq(
          [
            {first_name: "USER1", post: "123", post_reverse: "321"},
            {first_name: "USER2", post: "234", post_reverse: "432"}
          ]
        )
      end
    end

    context "with activerecord_preloads plugin" do
      let(:base_serializer) do
        Class.new(Serega) do
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

      context "with batch loaded AR objects" do
        let(:user_serializer) do
          p_serializer = post_serializer
          groups = method(:groups)
          Class.new(base_serializer) do
            attribute :first_name
            attribute :last_name
            attribute :posts, serializer: p_serializer, preload: :posts,
              batch: {key: :id, loader: proc { |ids| groups.call(AR::Post.where(user_id: ids).order(:text), by: :user_id) }}
          end
        end

        let(:post_serializer) do
          c_serializer = comment_serializer
          groups = method(:groups)
          Class.new(base_serializer) do
            attribute :text
            attribute :comments, serializer: c_serializer, preload: :comments,
              batch: {key: :id, loader: proc { |ids| groups.call(AR::Comment.where(post_id: ids).order(:text), by: :post_id) }}
          end
        end

        let(:comment_serializer) do
          Class.new(base_serializer) do
            attribute :text
          end
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

        it "preloads data to batch loaded activerecord objects", :with_rollback do
          users = AR::User.all
          result = user_serializer.to_h(users)

          expect(result).to eq(
            [
              {
                first_name: "Bruce",
                last_name: "Wayne",
                posts: [
                  {
                    text: "post1",
                    comments: [{text: "comment1"}, {text: "comment2"}]
                  },
                  {
                    text: "post2",
                    comments: [{text: "comment3"}]
                  }
                ]
              }
            ]
          )
          expect(users.loaded?).to be true
          expect(users[0].posts.loaded?).to be true
          expect(users[0].posts[0].comments.loaded?).to be true
        end
      end

      context "with batch loaded regular data" do
        let(:user_serializer) do
          Class.new(base_serializer) do
            attribute :first_name
            attribute :last_name
            attribute :posts_count,
              batch: {key: :id, loader: proc { |ids| AR::Post.where(user_id: ids).group(:user_id).count }}

            attribute :comments_count,
              batch: {key: :id, loader: proc { |ids| AR::Comment.joins(:post).where(posts: {user_id: ids}).group(:user_id).count }}
          end
        end

        it "works correctly", :with_rollback do
          users = AR::User.all
          result = user_serializer.to_h(users)

          expect(result).to eq(
            [
              {
                first_name: "Bruce",
                last_name: "Wayne",
                posts_count: 2,
                comments_count: 3
              }
            ]
          )
        end
      end
    end
  end
end