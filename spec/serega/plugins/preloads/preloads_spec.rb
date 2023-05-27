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
end
