# frozen_string_literal: true

require "support/activerecord"

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch do
  let(:serializer) { Class.new(Serega) { plugin :batch } }

  describe "Attribute methods" do
    describe "#batch" do
      it "returns provided options with transformed Symbol key to Proc" do
        batch_loader = proc {}
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

      it "returns key without changes if non-Symbol provided" do
        key = proc { :id }
        at = serializer.attribute :at, batch: {loader: :loader, key: key}
        expect(at.batch[:key]).to eq key
      end

      it "raises error with name of serializer and attribute when object does not respond to provided key" do
        at = serializer.attribute :foo, batch: {loader: :loader_name, key: :ping}
        expect { at.batch[:key].call(1) }.to raise_error start_with("NoMethodError when serializing 'foo' attribute in #{serializer}")
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
      attribute = serializer.attribute :foo, batch: {key: :id, loader: proc {}}

      expect(attribute.hide).to be true
    end

    it "does not overwrites attribute :hide option when auto_hide: true provided" do
      serializer.config.batch.auto_hide = true
      attribute = serializer.attribute :foo, batch: {key: :id, loader: proc {}}, hide: false

      expect(attribute.hide).to be false
    end

    it "does not change default (nil) :hide option when :auto_hide is false" do
      serializer.config.batch.auto_hide = false
      attribute = serializer.attribute :foo, batch: {key: :id, loader: proc {}}

      expect(attribute.hide).to be_nil
    end
  end
end
