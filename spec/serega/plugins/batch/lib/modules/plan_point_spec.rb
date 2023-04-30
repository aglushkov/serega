# frozen_string_literal: true

require "support/activerecord"

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch do
  let(:serializer) { Class.new(Serega) { plugin :batch } }

  describe "PlanPoint methods" do
    describe "#batch" do
      it "returns provided attribute #batch option" do
        loader = proc {}
        attribute = serializer.attribute :foo,
          batch: {loader: loader, key: :id}

        batch = serializer::SeregaPlanPoint.new(attribute, []).batch

        expect(batch).to eq attribute.batch
      end

      it "uses loader from serializer config when Symbol provided" do
        loader = proc {}
        serializer.config.batch.define(:loader_name, &loader)
        attribute = serializer.attribute :foo,
          batch: {loader: :loader_name, key: :id}

        batch = serializer::SeregaPlanPoint.new(attribute, []).batch
        expect(batch[:loader]).to eq loader
      end

      it "raises error when loader not defined" do
        attribute = serializer.attribute :foo,
          batch: {loader: :loader_name, key: :id}

        expect { serializer::SeregaPlanPoint.new(attribute) }.to raise_error Serega::SeregaError,
          start_with("Batch loader with name `:loader_name` was not defined")
      end
    end
  end
end
