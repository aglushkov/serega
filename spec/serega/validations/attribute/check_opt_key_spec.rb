# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckOptKey do
  def error(value)
    "Invalid option :key => #{value.inspect}. Must be a String or a Symbol"
  end

  it "allows only boolean values" do
    expect { described_class.call(key: :foo) }.not_to raise_error
    expect { described_class.call(key: "foo") }.not_to raise_error
    expect { described_class.call(key: nil) }.to raise_error Serega::Error, error(nil)
    expect { described_class.call(key: 123) }.to raise_error Serega::Error, error(123)
  end

  it "prohibits to use with :value opt" do
    expect { described_class.call(key: :foo, value: -> {}) }
      .to raise_error Serega::Error, "Option :key can not be used together with option :value"
  end

  it "prohibits to use with :const opt" do
    expect { described_class.call(key: :foo, const: 1) }
      .to raise_error Serega::Error, "Option :key can not be used together with option :const"
  end

  it "prohibits to use with block" do
    expect { described_class.call({key: :foo}, proc {}) }
      .to raise_error Serega::Error, "Option :key can not be used together with block"
  end
end
