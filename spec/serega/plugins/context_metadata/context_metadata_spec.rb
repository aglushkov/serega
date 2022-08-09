# frozen_string_literal: true

load_plugin_code :context_metadata

RSpec.describe Serega::SeregaPlugins::ContextMetadata do
  describe "loading" do
    it "loads additional :root plugin if was not loaded before" do
      serializer = Class.new(Serega) { plugin :context_metadata }
      expect(serializer.plugin_used?(:root)).to be true
    end

    it "loads additional :root plugin with custom root config" do
      serializer = Class.new(Serega) { plugin :context_metadata, root_one: :user, root_many: :users }
      expect(serializer.config.root.one).to eq :user
      expect(serializer.config.root.many).to eq :users
    end

    it "adds default :context_metadata_key config option" do
      serializer = Class.new(Serega) { plugin :context_metadata }
      expect(serializer.config.context_metadata.key).to eq :meta
    end

    it "adds specified :context_metadata_key config option" do
      serializer = Class.new(Serega) { plugin :context_metadata, context_metadata_key: :metadata }
      expect(serializer.config.context_metadata.key).to eq :metadata
    end
  end

  describe "configuration" do
    it "allows to change context_metadata key config option" do
      serializer = Class.new(Serega) { plugin :context_metadata }

      serializer.config.context_metadata.key = :foo
      expect(serializer.config.context_metadata.key).to eq :foo
    end
  end

  describe "validations" do
    let(:default_serializer) { Class.new(Serega) { plugin :context_metadata } }

    it "raises error when default context meta key is not a Hash" do
      ser = Class.new(Serega) { plugin :context_metadata }
      expect { ser.new.to_h(nil, meta: []) }
        .to raise_error Serega::SeregaError, "Invalid option :meta => []. Must have a Hash value"
    end

    it "raises error when configured context meta key is not a Hash" do
      ser = Class.new(Serega) { plugin :context_metadata, context_metadata_key: :foo }
      expect { ser.new.to_h(nil, foo: []) }
        .to raise_error Serega::SeregaError, "Invalid option :foo => []. Must have a Hash value"
    end
  end

  describe "serialization" do
    subject(:response) { user_serializer.new.to_h(obj, **opts) }

    let(:obj) { double(first_name: "FIRST_NAME") }
    let(:opts) { {meta: {version: "1.2.3"}} }
    let(:base_serializer) { Class.new(Serega) { plugin :context_metadata } }
    let(:user_serializer) do
      Class.new(base_serializer) do
        attribute :first_name
      end
    end

    context "with single object" do
      it "appends metadata attributes to response" do
        expect(response).to eq(data: {first_name: "FIRST_NAME"}, version: "1.2.3")
      end
    end

    context "with multiple objects" do
      let(:obj) { [double(first_name: "FIRST_NAME")] }

      it "appends metadata attributes to response" do
        expect(response).to eq(data: [{first_name: "FIRST_NAME"}], version: "1.2.3")
      end
    end

    context "when setting metadata key to nil" do
      before do
        user_serializer.config.context_metadata.key = nil
      end

      it "skips adding metadata to response" do
        expect(response).to eq(data: {first_name: "FIRST_NAME"})
      end
    end

    context "when metadata is not added" do
      let(:opts) { {} }

      it "skips adding any metadata to response" do
        expect(response).to eq(data: {first_name: "FIRST_NAME"})
      end
    end

    context "with :metadata plugin" do
      let(:serializer) do
        Class.new(Serega) do
          plugin :metadata
          plugin :context_metadata

          meta_attribute(:foo, :one) { 1 }
          meta_attribute(:foo, :two) { 2 }
        end
      end

      it "merges metadata" do
        opts = {meta: {foo: {two: "two", three: "three"}}}
        response = serializer.new.to_h(nil, **opts)
        expect(response).to eq(
          data: {},
          foo: {one: 1, two: "two", three: "three"}
        )
      end
    end
  end
end
