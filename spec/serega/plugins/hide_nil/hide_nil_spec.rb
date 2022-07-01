# frozen_string_literal: true

load_plugin_code :hide_nil

RSpec.describe Serega::Plugins::HideNil do
  let(:serializer_class) { Class.new(Serega) }

  it "adds allowed attribute options" do
    serializer_class.plugin :hide_nil
    attribute_keys = serializer_class.config[:attribute_keys]
    expect(attribute_keys).to include :hide_nil
  end

  describe "AttributeMethods" do
    before { serializer_class.plugin :hide_nil }

    describe "#hide_nil?" do
      it "returns :hide_nil option as boolean value" do
        attribute = serializer_class.attribute :foo
        expect(attribute.hide_nil?).to be false

        attribute = serializer_class.attribute :foo, hide_nil: false
        expect(attribute.hide_nil?).to be false

        attribute = serializer_class.attribute :foo, hide_nil: true
        expect(attribute.hide_nil?).to be true
      end

      it "raises error when not boolean value provided" do
        expect { serializer_class.attribute :foo, hide_nil: 1 }
          .to raise_error Serega::Error, "Invalid option :hide_nil => 1. Must have a boolean value"
      end
    end
  end

  describe "serializing" do
    it "hides hide_niled attributes when value is nil" do
      serializer_class.plugin :hide_nil

      another_serializer = Class.new(Serega)
      serializer_class.attribute(:foo) { "foo" }
      serializer_class.attribute(:bar, hide_nil: true) {}
      serializer_class.attribute(:bazz, serializer: another_serializer, hide_nil: true) {}

      expect(serializer_class.new.to_h(1)).to eq(foo: "foo")
    end

    it "does not hide false/empty attributes" do
      serializer_class.plugin :hide_nil
      serializer_class.attribute(:foo, hide_nil: true) { false }
      serializer_class.attribute(:bar, hide_nil: true) { "" }
      serializer_class.attribute(:bazz, hide_nil: true) { [] }

      expect(serializer_class.new.to_h(1)).to eq(foo: false, bar: "", bazz: [])
    end
  end
end
