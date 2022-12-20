# frozen_string_literal: true

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch::BatchOptionModel do
  let(:serializer) { Class.new(Serega) { plugin :batch } }

  describe "BatchOptionModel" do
    describe "#loader" do
      it "returns provided Proc loader" do
        loader = proc {}
        attribute = serializer.attribute :foo, batch: {loader: loader, key: :id}
        model = described_class.new(attribute)

        expect(model.loader).to eq loader
      end

      it "returns loader found by Symbol name" do
        loader = proc {}
        attribute = serializer.attribute :foo, batch: {loader: :loader_name, key: :id}
        serializer.config.batch_loaders.define(:loader_name, &loader)
        model = described_class.new(attribute)

        expect(model.loader).to eq loader
      end

      it "raises error when loader not defined" do
        attribute = serializer.attribute :foo, batch: {loader: :loader_name, key: :id}
        model = described_class.new(attribute)

        expect { model.loader }.to raise_error Serega::SeregaError, start_with("Batch loader with name `:loader_name` was not defined")
      end
    end

    describe "#key" do
      it "returns provided Proc key" do
        key = proc {}
        attribute = serializer.attribute :foo, batch: {loader: :loader_name, key: key}
        model = described_class.new(attribute)

        expect(model.key).to eq key
      end

      it "constructs Proc using key as method name" do
        attribute = serializer.attribute :foo, batch: {loader: :loader_name, key: :ping}
        model = described_class.new(attribute)
        object = double(ping: "PONG")

        expect(model.key.call(object)).to eq "PONG"
      end

      it "raises error with name of serializer and attribute when object does not respond to provided key" do
        attribute = serializer.attribute :foo, batch: {loader: :loader_name, key: :ping}
        model = described_class.new(attribute)
        object = "FOO"

        expect { model.key.call(object) }.to raise_error start_with("NoMethodError when serializing 'foo' attribute in #{serializer}")
      end
    end

    describe "#default_value" do
      it "returns nil by default" do
        attribute = serializer.attribute :foo, batch: {loader: :loader_name, key: :id}
        model = described_class.new(attribute)

        expect(model.default_value).to be_nil
      end

      it "returns provided default" do
        default = 10
        attribute = serializer.attribute :foo, batch: {loader: :loader_name, key: :id, default: default}
        model = described_class.new(attribute)

        expect(model.default_value).to eq default
      end

      it "returns empty Array by default when many=true" do
        attribute = serializer.attribute :foo, many: true, batch: {loader: :loader_name, key: :id}
        model = described_class.new(attribute)

        expect(model.default_value).to be Serega::FROZEN_EMPTY_ARRAY
      end

      it "returns provided default when many=true" do
        default = 10
        attribute = serializer.attribute :foo, many: true, batch: {loader: :loader_name, key: :id, default: default}
        model = described_class.new(attribute)

        expect(model.default_value).to eq default
      end
    end
  end
end
