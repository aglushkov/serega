# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::Plugins::Preloads do
  let(:serializer_class) { Class.new(Serega) }

  it "adds allowed attribute options" do
    serializer_class.plugin :preloads
    attribute_keys = serializer_class.config[:attribute_keys]
    expect(attribute_keys).to include :preload
    expect(attribute_keys).to include :preload_path
  end

  it "configures to not preload attributes with serializer by default" do
    serializer_class.plugin :preloads
    expect(serializer_class.config[:preloads][:auto_preload_attributes_with_serializer]).to be false
  end

  it "allows to configure to not preload relations by default" do
    serializer_class.plugin :preloads, auto_preload_attributes_with_serializer: false
    expect(serializer_class.config[:preloads][:auto_preload_attributes_with_serializer]).to be false
  end

  describe "InstanceMethods" do
    it "adds #preloads method as a delegator to #{described_class}::PreloadsConstructor" do
      serializer_class.plugin :preloads
      serializer = serializer_class.new
      map = serializer.send(:map)

      allow(described_class::PreloadsConstructor).to receive(:call).with(map).and_return("RES")

      expect(serializer.preloads).to be "RES"
    end
  end

  describe "AttributeMethods" do
    before { serializer_class.plugin :preloads }

    describe "#preloads" do
      it "returns empty hash for regular attributes" do
        attribute = serializer_class.attribute :foo
        expect(attribute.preloads).to eq({})
      end

      it "returns nil when provided nil" do
        attribute = serializer_class.attribute :foo, preload: nil
        expect(attribute.preloads).to be_nil
      end

      it "returns formatted provided preloads" do
        attribute = serializer_class.attribute :foo, preload: :bar
        expect(attribute.preloads).to eq(bar: {})
      end

      it "returns automatically found preloads when serializer provided" do
        serializer_class.config[:preloads][:auto_preload_attributes_with_serializer] = true
        attribute = serializer_class.attribute :foo, serializer: "bar"
        expect(attribute.preloads).to eq(foo: {})
      end

      it "returns no preloads for attributes with serializer by default" do
        attribute = serializer_class.attribute :foo, serializer: "bar"
        expect(attribute.preloads).to eq({})
      end
    end

    describe "#preload_path" do
      it "returns constructed preload_path" do
        attribute = serializer_class.attribute :foo, preload: :foo
        expect(attribute.preloads_path).to eq([:foo])
        expect(attribute.preloads_path).to be_frozen
      end

      it "returns provided preload_path" do
        attribute = serializer_class.attribute :foo, serializer: "foo", preload: %i[bar bazz], preload_path: :bar
        expect(attribute.preloads_path).to eq([:bar])
        expect(attribute.preloads_path).to be_frozen
      end
    end

    describe "checking preload_path option" do
      let(:validator) { described_class::CheckOptPreloadPath }

      it "validates options with CheckOptPreloadPath" do
        allow(validator).to receive(:call).and_return(nil)
        attribute = serializer_class.attribute :foo
        expect(validator).to have_received(:call).with(attribute.opts)
      end
    end
  end
end
