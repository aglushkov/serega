# frozen_string_literal: true

RSpec.describe Serega do
  let(:serializer_class) { Class.new(described_class) }

  it "has a version number" do
    expect(described_class::VERSION).not_to be_nil
  end

  describe ".config" do
    subject(:config) { serializer_class.config }

    it "generates default config" do
      expect(config.keys).to match_array %i[
        plugins
        initiate_keys
        serialize_keys
        attribute_keys
        check_initiate_params
        max_cached_map_per_serializer_count
        to_json
      ]

      expect(config[:plugins]).to eq []
      expect(config[:serialize_keys]).to match_array(%i[context many])
      expect(config[:initiate_keys]).to match_array(%i[only except with check_initiate_params])
      expect(config[:attribute_keys]).to match_array(%i[key value serializer many hide const delegate])
      expect(config[:max_cached_map_per_serializer_count]).to eq 0
      expect(config[:to_json].call({})).to eq "{}"
    end
  end

  describe ".inherited" do
    it "inherits config" do
      parent = Class.new(described_class)
      parent.config[:foo] = :bar

      # Check config values are inherited
      child = Class.new(parent)
      expect(child.config[:foo]).to eq :bar

      # Check child config does not overwrite parent config values
      child.config[:foo] = 123
      expect(parent.config[:foo]).to eq :bar

      # Check child config does not adds new keys to parent config
      child.config[:bar] = 123
      expect(parent.config).not_to have_key(:bar)

      # Check child config is a subclass of parent config
      expect(child.config.class.superclass).to eq parent.config.class
    end

    it "inherits attributes" do
      parent = Class.new(described_class)
      parent.attribute(:foo)

      # Check attributes are copied to child attributes
      child = Class.new(parent)
      expect(child.attributes[:foo].class.superclass).to eq parent.attributes[:foo].class
    end

    it "inherits serialization classes" do
      parent = Class.new(described_class)
      child = Class.new(parent)

      # Check child serialization classes are subclassed from parent classes
      expect(child::SeregaConvert.superclass).to eq parent::SeregaConvert
      expect(child::SeregaConvertItem.superclass).to eq parent::SeregaConvertItem
    end
  end

  describe ".plugin" do
    let(:plugin) { Module.new }

    it "runs plugin callbacks" do
      opts = {foo: :bar}
      allow(plugin).to receive_messages(
        before_load_plugin: nil,
        load_plugin: nil,
        after_load_plugin: nil
      )
      serializer_class.plugin(plugin, **opts)

      expect(plugin).to have_received(:before_load_plugin).with(serializer_class, opts)
      expect(plugin).to have_received(:load_plugin).with(serializer_class, opts)
      expect(plugin).to have_received(:after_load_plugin).with(serializer_class, opts)
    end

    it "loads not registered plugins modules" do
      serializer_class.plugin plugin
      expect(serializer_class.config[:plugins]).to eq [plugin]
    end

    it "loads registered plugins using plugin_name" do
      plugin.instance_exec do
        def self.plugin_name
          :test
        end
      end

      Serega::SeregaPlugins.register_plugin(plugin.plugin_name, plugin)

      serializer_class.plugin(:test)
      expect(serializer_class.config[:plugins]).to eq [:test]
    end

    it "raises error if plugin is already loaded" do
      serializer_class.plugin(plugin)
      expect { serializer_class.plugin(plugin) }.to raise_error Serega::SeregaError, "This plugin is already loaded"
    end
  end

  describe ".plugin_used?" do
    it "tells if plugin has been already used in current serializer" do
      plugin = Module.new
      expect(serializer_class.plugin_used?(plugin)).to be false
      serializer_class.plugin(plugin)
      expect(serializer_class.plugin_used?(plugin)).to be true
    end

    it "tells if plugin has been already used in current serializer when given plugin name" do
      plugin = Module.new do
        def self.plugin_name
          :test
        end
      end

      Serega::SeregaPlugins.register_plugin(plugin.plugin_name, plugin)

      expect(serializer_class.plugin_used?(:test)).to be false
      serializer_class.plugin(:test)
      expect(serializer_class.plugin_used?(:test)).to be true
    end
  end

  describe ".attribute" do
    it "adds new attribute" do
      attribute = serializer_class.attribute "foo"
      expect(serializer_class.attributes).to eq(foo: attribute)
    end
  end

  describe ".attributes" do
    it "returns empty hash when no attributes added" do
      expect(serializer_class.attributes).to eq({})
    end

    it "returns list of added attributes" do
      foo = serializer_class.attribute :foo
      bar = serializer_class.attribute :bar

      expect(serializer_class.attributes).to eq(foo: foo, bar: bar)
    end
  end

  describe "serialization methods" do
    let(:serializer_class) do
      Class.new(described_class) do
        attribute(:obj) { |obj| obj }
        attribute(:ctx) { |obj, ctx| ctx[:data] }
        attribute(:except) { "EXCEPT" }
      end
    end

    let(:opts) { {except: :except} }
    let(:serializer) { serializer_class.new(**opts) }

    describe "#call" do
      it "returns serialized response" do
        expect(serializer.call("foo", context: {data: "bar"}))
          .to eq({obj: "foo", ctx: "bar"})
      end
    end

    describe "#to_h" do
      it "returns serialized response same as .call method" do
        expect(serializer.to_h("foo", context: {data: "bar"}))
          .to eq({obj: "foo", ctx: "bar"})
      end
    end

    describe "#to_json" do
      it "returns serialized to json response" do
        expect(serializer.to_json("foo", context: {data: "bar"}))
          .to eq('{"obj":"foo","ctx":"bar"}')
      end
    end

    describe "#as_json" do
      it "returns serialized as json response (with JSON compatible types)" do
        expect(serializer.as_json("foo", context: {data: "bar"}))
          .to eq({"obj" => "foo", "ctx" => "bar"})
      end
    end

    describe ".call" do
      it "returns serialized to response" do
        expect(serializer_class.call("foo", **opts, context: {data: "bar"}))
          .to eq({obj: "foo", ctx: "bar"})
      end
    end

    describe ".to_h" do
      it "returns serialized response same as .call method" do
        expect(serializer_class.to_h("foo", **opts, context: {data: "bar"}))
          .to eq({obj: "foo", ctx: "bar"})
      end
    end

    describe ".to_json" do
      it "returns serialized to json response" do
        expect(serializer_class.to_json("foo", **opts, context: {data: "bar"}))
          .to eq('{"obj":"foo","ctx":"bar"}')
      end
    end

    describe ".as_json" do
      it "returns serialized as json response (with JSON compatible types)" do
        expect(serializer_class.as_json("foo", **opts, context: {data: "bar"}))
          .to eq({"obj" => "foo", "ctx" => "bar"})
      end
    end
  end

  describe "validating initiate params" do
    let(:validator) { instance_double(serializer_class::CheckInitiateParams, validate: nil) }
    let(:modifiers) { {only: "foo"} }

    before do
      allow(serializer_class::CheckInitiateParams).to receive(:new).and_return(validator)
    end

    it "validates initiate params by default" do
      serializer_class.to_h(nil, modifiers)

      expect(serializer_class::CheckInitiateParams).to have_received(:new).with(only: {foo: {}})
      expect(validator).to have_received(:validate)
    end

    it "allows to disable validation via config option" do
      serializer_class.config[:check_initiate_params] = false
      serializer_class.to_h(nil, modifiers)

      expect(serializer_class::CheckInitiateParams).not_to have_received(:new)
    end

    it "allows to disable validation via check_initiate_params param" do
      serializer_class.to_h(nil, **modifiers, check_initiate_params: false)

      expect(serializer_class::CheckInitiateParams).not_to have_received(:new)
    end
  end

  describe "validating serialize params" do
    let(:validator) { instance_double(serializer_class::CheckSerializeParams, validate: nil) }
    let(:params) { {only: {}, except: {}, with: {}, context: {foo: "bar"}, a: 1} }

    before do
      allow(serializer_class::CheckSerializeParams).to receive(:new).and_return(validator)
    end

    it "selects serialize params (not modifiers params) and validates them" do
      serializer_class.to_h(nil, params)

      expect(serializer_class::CheckSerializeParams).to have_received(:new).with(context: {foo: "bar"}, a: 1)
      expect(validator).to have_received(:validate)
    end
  end
end
