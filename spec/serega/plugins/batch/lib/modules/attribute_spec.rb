# frozen_string_literal: true

require "support/activerecord"

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch do
  let(:serializer) do
    Class.new(Serega) do
      plugin :batch

      config.batch.define(:loader, &proc {})
    end
  end

  describe "Attribute methods" do
    describe "#batch" do
      it "returns provided options with transformed Symbol key to Proc" do
        batch_loader = proc { |*args| }
        at = serializer.attribute :at1, batch: {key: :id, loader: batch_loader, default: :default}
        expect(at.batch).to include(loader: batch_loader)
        expect(at.batch).to include(default: :default)
        expect(at.batch).to include(key: be_a(Proc))

        object = double(id: "ID")
        expect(at.batch[:key].call(object)).to eq "ID"
      end

      it "returns default key added in serializer config" do
        serializer.config.batch.default_key = :id
        at = serializer.attribute :at, batch: {loader: :loader}
        expect(at.batch).to include({key: be_a(Proc)})

        object = double(id: 1)
        expect(at.batch[:key].call(object)).to eq 1
      end

      it "returns provided key instance when it accepts 2 params" do
        key = proc { |a, b| :id }
        at = serializer.attribute :at, batch: {loader: :loader, key: key}
        expect(at.batch[:key]).to eq key
      end

      it "returns normalized proc when single parameter callable provided" do
        key = lambda { |a| :foo }
        at = serializer.attribute :at, batch: {loader: :loader, key: key}
        expect(at.batch[:key]).not_to eq key
        expect(at.batch[:key].call(1)).to eq :foo
      end

      it "adds `default: nil` if attribute :many option not specified" do
        at = serializer.attribute :at, batch: {key: :id, loader: :loader}
        expect(at.batch).to include({default: nil})
      end

      it "adds `default: []` if attribute :many option is set" do
        at = serializer.attribute :at, batch: {key: :id, loader: :loader}, many: true
        expect(at.batch).to include({default: []})
      end
    end

    it "hides attributes with batch when auto_hide: true provided" do
      serializer.config.batch.auto_hide = true
      attribute = serializer.attribute :foo, batch: {key: :id, loader: proc { |keys| }}

      expect(attribute.hide).to be true
    end

    it "does not overwrites attribute :hide option when auto_hide: true provided" do
      serializer.config.batch.auto_hide = true
      attribute = serializer.attribute :foo, batch: {key: :id, loader: proc { |keys| }}, hide: false

      expect(attribute.hide).to be false
    end

    it "does not change default (nil) :hide option when :auto_hide is false" do
      serializer.config.batch.auto_hide = false
      attribute = serializer.attribute :foo, batch: {key: :id, loader: proc { |keys| }}

      expect(attribute.hide).to be_nil
    end
  end
end
