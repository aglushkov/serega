# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckOptConst do
  it "prohibits to use with :value opt" do
    expect { described_class.call(const: :foo, value: -> {}) }
      .to raise_error Serega::Error, "Option :const can not be used together with option :value"
  end

  it "prohibits to use with :key opt" do
    expect { described_class.call(key: :foo, const: 1) }
      .to raise_error Serega::Error, "Option :const can not be used together with option :key"
  end

  it "prohibits to use with block" do
    expect { described_class.call({const: :foo}, proc {}) }
      .to raise_error Serega::Error, "Option :const can not be used together with block"
  end
end
