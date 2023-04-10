# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::SeregaPlugins::Preloads do
  let(:serializer_class) { Class.new(Serega) }

  it "adds allowed attribute options" do
    serializer_class.plugin :preloads
    attribute_keys = serializer_class.config.attribute_keys
    expect(attribute_keys).to include :preload
    expect(attribute_keys).to include :preload_path
  end

  it "configures to not preload attributes with serializer by default" do
    serializer_class.plugin :preloads
    expect(serializer_class.config.preloads.auto_preload_attributes_with_serializer).to be false
  end

  it "configures to not preload attributes with :delegate option by default" do
    serializer_class.plugin :preloads
    expect(serializer_class.config.preloads.auto_preload_attributes_with_delegate).to be false
  end

  it "configures to not hide attributes with preload option by default" do
    serializer_class.plugin :preloads
    expect(serializer_class.config.preloads.auto_hide_attributes_with_preload).to be false
  end

  it "allows to configure to preload attributes with serializer by default" do
    serializer_class.plugin :preloads, auto_preload_attributes_with_serializer: true
    expect(serializer_class.config.preloads.auto_preload_attributes_with_serializer).to be true
  end

  it "allows to configure to preload attributes with :delegate option by default" do
    serializer_class.plugin :preloads, auto_preload_attributes_with_delegate: true
    expect(serializer_class.config.preloads.auto_preload_attributes_with_delegate).to be true
  end

  it "allows to configure to hide attributes with preloads by default" do
    serializer_class.plugin :preloads, auto_hide_attributes_with_preload: true
    expect(serializer_class.config.preloads.auto_hide_attributes_with_preload).to be true
  end

  it "raises error when not boolean value provided to auto_preload_attributes_with_serializer" do
    expect { serializer_class.plugin :preloads, auto_preload_attributes_with_serializer: nil }
      .to raise_error Serega::SeregaError, "Must have boolean value, #{nil.inspect} provided"
  end

  it "raises error when not boolean value provided to auto_preload_attributes_with_delegate" do
    expect { serializer_class.plugin :preloads, auto_preload_attributes_with_delegate: nil }
      .to raise_error Serega::SeregaError, "Must have boolean value, #{nil.inspect} provided"
  end

  it "raises error when not boolean value provided to auto_hide_attributes_with_preload" do
    expect { serializer_class.plugin :preloads, auto_hide_attributes_with_preload: nil }
      .to raise_error Serega::SeregaError, "Must have boolean value, #{nil.inspect} provided"
  end

  describe "InstanceMethods" do
    it "adds #preloads method as a delegator to #{described_class}::PreloadsConstructor" do
      serializer_class.plugin :preloads
      serializer = serializer_class.new
      plan = serializer.send(:plan)

      allow(described_class::PreloadsConstructor).to receive(:call).with(plan).and_return("RES")

      expect(serializer.preloads).to be "RES"
    end
  end

  describe "MapPointMethods" do
    before { serializer_class.plugin :preloads }

    def point(attribute, nested_points)
      attribute.class.serializer_class::SeregaPlanPoint.new(attribute, nested_points)
    end

    it "delegates #preloads_path to attribute" do
      attribute = serializer_class.attribute :foo, preload: :bar
      expect(attribute.preloads).to eq(bar: {})

      point = serializer_class::SeregaPlanPoint.new(attribute, nil)
      expect(point.preloads_path).to eq([:bar])
    end

    it "constructs #preloads for all nested preloads" do
      foo = serializer_class.attribute :foo, preload: :foo, serializer: serializer_class
      bar = serializer_class.attribute :bar, preload: :bar, serializer: serializer_class

      p = point(foo, nil)
      expect(p.preloads).to eq({})

      p = point(foo, [point(foo, nil)])
      expect(p.preloads).to eq({foo: {}})

      p = point(foo, [point(foo, nil), point(bar, nil)])
      expect(p.preloads).to eq({foo: {}, bar: {}})

      p = point(foo, [point(foo, nil), point(bar, [point(foo, nil)])])
      expect(p.preloads).to eq({foo: {}, bar: {foo: {}}})
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
        serializer_class.config.preloads.auto_preload_attributes_with_serializer = true
        attribute = serializer_class.attribute :foo, serializer: "bar"
        expect(attribute.preloads).to eq(foo: {})
      end

      it "returns no preloads for attributes with serializer by default" do
        attribute = serializer_class.attribute :foo, serializer: "bar"
        expect(attribute.preloads).to eq({})
      end

      it "returns automatically found preloads when :delegate option provided" do
        serializer_class.config.preloads.auto_preload_attributes_with_delegate = true
        attribute = serializer_class.attribute :foo, delegate: {to: :bar}
        expect(attribute.preloads).to eq(bar: {})
      end

      it "returns no preloads for attributes with :delegate option by default" do
        attribute = serializer_class.attribute :foo, delegate: {to: :bar}
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

    describe "checking preload option" do
      let(:validator) { described_class::CheckOptPreload }

      it "validates options with CheckOptPreload" do
        allow(validator).to receive(:call).and_return(nil)
        attribute = serializer_class.attribute :foo
        expect(validator).to have_received(:call).with(attribute.opts)
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

    describe "#hide" do
      context "without auto_hide config" do
        it "returns opt :hide" do
          a0 = serializer_class.attribute :a0
          a1 = serializer_class.attribute :a1, preload: :a1
          a2 = serializer_class.attribute :a2, preload: :a2, hide: true
          a3 = serializer_class.attribute :a3, preload: :a3, hide: false

          expect(a0.hide).to be_nil
          expect(a1.hide).to be_nil
          expect(a2.hide).to be true
          expect(a3.hide).to be false
        end
      end

      context "with auto_hide config" do
        before do
          serializer_class.config.preloads.auto_hide_attributes_with_preload = true
        end

        it "returns opt :hide => true when preload is not blank" do
          a0 = serializer_class.attribute :a0
          a1 = serializer_class.attribute :a1, preload: :a1
          a2 = serializer_class.attribute :a2, preload: :a2, hide: true
          a3 = serializer_class.attribute :a3, preload: :a3, hide: false
          a4 = serializer_class.attribute :a4, preload: nil
          a5 = serializer_class.attribute :a5, preload: false
          a6 = serializer_class.attribute :a6, preload: {}
          a7 = serializer_class.attribute :a7, preload: []

          expect(a0.hide).to be_nil
          expect(a1.hide).to be true
          expect(a2.hide).to be true
          expect(a3.hide).to be false
          expect(a4.hide).to be_nil
          expect(a5.hide).to be_nil
          expect(a6.hide).to be_nil
          expect(a7.hide).to be_nil
        end
      end
    end
  end
end
