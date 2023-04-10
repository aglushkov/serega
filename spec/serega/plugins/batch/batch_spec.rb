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

  describe "MapPoint methods" do
    specify "#batch" do
      batch_loader = proc {}
      at1 = serializer.attribute :at1, many: true, batch: {key: :key, loader: batch_loader}
      at2 = serializer.attribute :bar
      pt1 = serializer::SeregaPlanPoint.new(at1, [])
      pt2 = serializer::SeregaPlanPoint.new(at2, [])

      batch = pt1.batch
      expect(batch).to be_a Serega::SeregaPlugins::Batch::BatchOptionModel
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
          attribute :online_time, batch: {key: :online_id, loader: proc { |_ids, _ctx, _point| {1 => 10, 2 => 20} }}
          attribute :offline_time, batch: {key: :offline_id, loader: proc { |_ids, _ctx, _point| {3 => 30, 4 => 40} }}
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

      it "works when caching enabled" do
        user_serializer.config.max_cached_plans_per_serializer_count = 10

        first_result = user_serializer.to_h(users)
        second_result = user_serializer.to_h(users)
        expect(first_result).to eq second_result
      end
    end

    context "when batch result is not a Hash" do
      let(:user_serializer) do
        Class.new(Serega) do
          plugin :batch
          attribute :online_time, batch: {key: :online_id, loader: proc { 1 }}
        end
      end

      let(:user) { double(first_name: "USER1", online_id: 1) }

      it "raises error" do
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
            batch: {key: :status_id, loader: proc { |ids, _ctx, _point| {1 => all_statuses[0], 2 => all_statuses[1]} }}
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

      it "works when caching enabled" do
        user_serializer.config.max_cached_plans_per_serializer_count = 10

        first_result = user_serializer.to_h(users)
        second_result = user_serializer.to_h(users)
        expect(first_result).to eq second_result
      end
    end

    context "with batch load inside batch_load" do
      let(:status_serializer) do
        Class.new(Serega) do
          plugin :batch
          attribute :name,
            batch: {key: :id, loader: proc { |ids, _ctx, _point| {1 => "draft", 2 => "published"} }}
        end
      end

      let(:post_serializer) do
        st_serializer = status_serializer
        all_statuses = statuses
        Class.new(Serega) do
          plugin :batch
          attribute :status, serializer: st_serializer,
            batch: {key: :status_id, loader: proc { |ids, _ctx, _point| {1 => all_statuses[0], 2 => all_statuses[1]} }}
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
            batch: {key: :post_id, loader: proc { |ids, _ctx, _point| {1 => all_posts[0], 2 => all_posts[1]} }}
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
  end
end
