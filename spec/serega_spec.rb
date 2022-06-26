# frozen_string_literal: true

RSpec.describe Serega do
  let(:serializer_class) { Class.new(described_class) }

  it "has a version number" do
    expect(described_class::VERSION).not_to be nil
  end

  describe ".config" do
    subject(:config) { serializer_class.config }

    it "generates default config" do
      expect(config.keys).to eq %i[
        plugins
        allowed_opts
        max_cached_map_per_serializer_count
        to_json
      ]

      expect(config[:plugins]).to eq []
      expect(config[:allowed_opts]).to eq %i[key serializer many hide]
      expect(config[:max_cached_map_per_serializer_count]).to eq 50
      expect(config[:to_json].call({})).to eq "{}"
    end
  end

  describe ".inherited" do
    it "inherits config" do
      parent = Class.new(Serega)
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
      parent = Class.new(Serega)
      parent.attribute(:foo)

      # Check attributes are copied to child attributes
      child = Class.new(parent)
      expect(child.attributes[:foo].class.superclass).to eq parent.attributes[:foo].class
    end

    it "inherits serialization classes" do
      parent = Class.new(Serega)
      child = Class.new(parent)

      # Check child serialization classes are subclassed from parent classes
      expect(child::Convert.superclass).to eq parent::Convert
      expect(child::ConvertItem.superclass).to eq parent::ConvertItem
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

      Serega::Plugins.register_plugin(plugin.plugin_name, plugin)

      serializer_class.plugin(:test)
      expect(serializer_class.config[:plugins]).to eq [:test]
    end

    it "raises error if plugin is already loaded" do
      serializer_class.plugin(plugin)
      expect { serializer_class.plugin(plugin) }.to raise_error Serega::Error, "This plugin is already loaded"
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

      Serega::Plugins.register_plugin(plugin.plugin_name, plugin)

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

  describe ".relation" do
    it "forces using of :serializer option" do
      expect { serializer_class.relation :foo }.to raise_error ArgumentError, /serializer/
    end

    it "adds new attribute" do
      attribute = serializer_class.relation(:foo, serializer: serializer_class)
      expect(serializer_class.attributes[:foo]).to eq attribute
    end
  end

  describe "serialization methods" do
    let(:serializer_class) do
      Class.new(described_class) do
        attribute(:obj) { |obj| obj }
        attribute(:ctx) { |obj, ctx| ctx[:data] }
      end
    end

    let(:serializer) { serializer_class.new }

    describe "#to_h" do
      it "returns serialized to hash response" do
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
  end
end
