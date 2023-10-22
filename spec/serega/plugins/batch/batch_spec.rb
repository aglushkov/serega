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

    it "adds option :auto_hide (false by default)" do
      auto_hide = serializer.config.batch.auto_hide
      expect(auto_hide).to be false
    end

    it "allows to change :auto_hide option when defining plugin" do
      serializer = Class.new(Serega) { plugin :batch, auto_hide: true }
      auto_hide = serializer.config.batch.auto_hide
      expect(auto_hide).to be true
    end

    it "adds option :default_key (nil by default)" do
      default_key = serializer.config.batch.default_key
      expect(default_key).to be_nil
    end

    it "allows to change :default_key option when defining plugin" do
      serializer = Class.new(Serega) { plugin :batch, default_key: :id }
      default_key = serializer.config.batch.default_key
      expect(default_key).to eq :id
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
      expect { serializer.attribute :foo, batch: {key: :key, loader: proc { |keys| }} }.not_to raise_error
    end
  end

  describe "attributes options" do
    it "allows to provide loader with 1 argument" do
      loader = lambda { |a| a }
      attribute = serializer.attribute :foo, batch: {key: :key, loader: loader}
      expect(attribute.batch[:loader].call(1, 2, 3)).to eq 1
    end

    it "allows to provide loader with 2 arguments" do
      loader = lambda { |a, b| b }
      attribute = serializer.attribute :foo, batch: {key: :key, loader: loader}
      expect(attribute.batch[:loader].call(1, 2, 3)).to eq 2
    end

    it "allows to provide loader with 3 arguments" do
      loader = lambda { |a, b, c| c }
      attribute = serializer.attribute :foo, batch: {key: :key, loader: loader}
      expect(attribute.batch[:loader].call(1, 2, 3)).to eq 3
    end
  end

  describe "serialization" do
    context "when no batch loaded attributes" do
      subject(:result) { user_serializer.to_h(user) }

      let(:user_serializer) do
        Class.new(Serega) do
          plugin :batch
          attribute :first_name
        end
      end

      let(:user) { double(first_name: "USER") }

      it "does not raise errors" do
        expect(result).to eq({first_name: "USER"})
      end
    end

    context "with simple batch loaded value" do
      subject(:result) { user_serializer.to_h(users) }

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

    context "with some error in batch loader" do
      subject(:result) { user_serializer.to_h(user) }

      let(:user_serializer) do
        Class.new(Serega) do
          plugin :batch, default_key: :online_id

          attribute :first_name
          attribute :online_time, batch: {loader: proc { |keys| foobar }} # not existing variable call
        end
      end

      let(:user) { double(first_name: "USER1", online_id: 1) }

      it "raises error with specified attribute name and serializer class" do
        expect { result }.to raise_error NameError,
          end_with("(when serializing 'online_time' attribute in #{user_serializer})")
      end
    end

    context "when batch result is not a Hash" do
      subject(:result) { user_serializer.to_h(user) }

      let(:user_serializer) do
        Class.new(Serega) do
          plugin :batch
          attribute :online_time, batch: {key: :online_id, loader: proc { |keys| 1 }}
        end
      end

      let(:user) { double(first_name: "USER1", online_id: 1) }

      it "raises error" do
        expect { result }
          .to raise_error Serega::SeregaError, "Batch loader for `#{user_serializer}.online_time` must return Hash, but #{1.inspect} was returned"
      end
    end

    context "with batch loaded relation" do
      subject(:result) { user_serializer.to_h(users) }

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
            batch: {key: :status_id, loader: proc { |ids| {1 => all_statuses[0], 2 => all_statuses[1]} }}
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
      subject(:result) { user_serializer.to_h(users) }

      let(:status_serializer) do
        Class.new(Serega) do
          plugin :batch
          attribute :name,
            batch: {key: :id, loader: proc { |ids| {1 => "draft", 2 => "published"} }}
        end
      end

      let(:post_serializer) do
        st_serializer = status_serializer
        all_statuses = statuses
        Class.new(Serega) do
          plugin :batch
          attribute :status, serializer: st_serializer,
            batch: {key: :status_id, loader: proc { |ids| {1 => all_statuses[0], 2 => all_statuses[1]} }}
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
            batch: {key: :post_id, loader: proc { |ids| {1 => all_posts[0], 2 => all_posts[1]} }}
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

    context "when :batch plugin not defined for top serializer" do
      subject(:result) { user_serializer.to_h(user) }

      let(:status_serializer) do
        Class.new(Serega) do
          plugin :batch
          attribute :status,
            batch: {
              key: :id,
              loader: proc { |keys| }
            }
        end
      end

      let(:user_serializer) do
        statuses_serializer = status_serializer
        Class.new(Serega) do
          attribute :first_name
          attribute :status, serializer: statuses_serializer
        end
      end

      let(:user) { double(first_name: "USER1", status: double(id: 1)) }

      it "raises error that batch plugin must be added to parent serializer" do
        expect { result }.to raise_error Serega::SeregaError,
          "Plugin :batch must be added to current serializer (#{user_serializer})" \
          " to load attributes with :batch option in nested serializer (#{status_serializer})"
      end
    end
  end
end
