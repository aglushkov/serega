# frozen_string_literal: true

load_plugin_code :validate_modifiers

RSpec.describe Serega::Plugins::ValidateModifiers do
  let(:base_serializer) do
    serializer_class = Class.new(Serega)
    serializer_class.plugin :string_modifiers
    serializer_class.plugin :validate_modifiers
    serializer_class
  end

  let(:serializer) do
    serializer_class = Class.new(base_serializer)
    serializer_class.attribute :foo_bar
    serializer_class.relation :foo_bazz, serializer: serializer_class
    serializer_class
  end

  it "adds config option to auto validate by default" do
    expect(base_serializer.config[:validate_modifiers]).to eq(auto: true)
  end

  it "allows to change config option to auto validate when adding plugin" do
    serializer_class = Class.new(Serega)
    serializer_class.plugin :validate_modifiers, auto: false

    expect(serializer_class.config[:validate_modifiers]).to eq(auto: false)
  end

  it "does not raise error when all provided fields present" do
    expect { serializer.new(only: "foo_bar,foo_bazz(foo_bar)") }.not_to raise_error
  end

  it "raises error when some provided field not exist" do
    expect { serializer.new(only: "foo_bar,extra") }
      .to raise_error Serega::AttributeNotExist, "Attribute 'extra' not exists"
  end

  it "does not raise error when configured to not validate by default" do
    serializer.config[:validate_modifiers][:auto] = false

    ser = nil
    expect { ser = serializer.new(only: "foo_bar,extra") }.not_to raise_error
    expect { ser.validate_modifiers }
      .to raise_error Serega::AttributeNotExist, "Attribute 'extra' not exists"
  end

  it "validates deeply nested fields" do
    c = Class.new(base_serializer)
    c.attribute :c1
    c.attribute :c2

    b = Class.new(base_serializer)
    b.attribute :b1
    b.attribute :b2
    b.attribute :c, serializer: c

    a = Class.new(base_serializer)
    a.attribute :a1
    a.attribute :a2
    a.attribute :b, serializer: b
    a.attribute :c, serializer: c

    expect { a.new(with: "a1,a2,c(c1,c2),b(b1,b2,c(c1,c2,c3)") }
      .to raise_error Serega::Error, "Attribute 'c3' ('b.c.c3') not exists"
  end

  it "validates deeply nested fields about not existing relation" do
    c = Class.new(base_serializer)
    c.attribute :c1
    c.attribute :c2

    b = Class.new(base_serializer)
    b.attribute :b1
    b.attribute :b2
    b.attribute :c, serializer: c

    a = Class.new(base_serializer)
    a.attribute :a1
    a.attribute :a2
    a.attribute :b, serializer: b
    a.attribute :c, serializer: c

    expect { a.new(except: "a1,a2,c(c1,c2),b(b1,b2,c(c1,c2(c3))") }
      .to raise_error Serega::AttributeNotExist, "Attribute 'c2' ('b.c.c2') has no :serializer option specified to add nested 'c3' attribute"
  end
end
