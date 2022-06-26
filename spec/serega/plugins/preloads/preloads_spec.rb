# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::Plugins::Preloads do
  let(:serializer_class) { Class.new(Serega) }

  it "adds allowed attribute options" do
    serializer_class.plugin :preloads
    allowed_opts = serializer_class.config[:allowed_opts]
    expect(allowed_opts).to include :preload
    expect(allowed_opts).to include :preload_path
  end

  it "configures to preload relations by default" do
    serializer_class.plugin :preloads
    expect(serializer_class.config[:preloads][:auto_preload_relations]).to be true
  end

  it "allows to configure to not preload relations by default" do
    serializer_class.plugin :preloads, auto_preload_relations: false
    expect(serializer_class.config[:preloads][:auto_preload_relations]).to be false
  end

  describe "InstanceMethods" do
    it "adds #preloads method as a delegator to #{described_class}::PreloadsConstructor" do
      serializer_class.plugin :preloads
      serializer = serializer_class.new
      map = serializer.instance_variable_get(:@map)

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
        expect(attribute.preloads).to eq(nil)
      end

      it "returns formatted provided preloads" do
        attribute = serializer_class.attribute :foo, preload: :bar
        expect(attribute.preloads).to eq(bar: {})
      end

      it "returns automatically found preloads when serializer provided" do
        attribute = serializer_class.attribute :foo, serializer: "bar"
        expect(attribute.preloads).to eq(foo: {})
      end

      it "returns no preloads when serializer provided and auto_preload_relations is false" do
        serializer_class.config[:preloads][:auto_preload_relations] = false
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
