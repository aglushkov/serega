# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckOptMethod do
  def error(value)
    "Invalid option :method => #{value.inspect}. Must be a String or a Symbol"
  end

  it "allows only boolean values" do
    expect { described_class.call(method: :foo) }.not_to raise_error
    expect { described_class.call(method: "foo") }.not_to raise_error
    expect { described_class.call(method: nil) }.to raise_error Serega::SeregaError, error(nil)
    expect { described_class.call(method: 123) }.to raise_error Serega::SeregaError, error(123)
  end

  it "prohibits to use with :value opt" do
    expect { described_class.call(method: :foo, value: -> {}) }
      .to raise_error Serega::SeregaError, "Option :method can not be used together with option :value"
  end

  it "prohibits to use with :const opt" do
    expect { described_class.call(method: :foo, const: 1) }
      .to raise_error Serega::SeregaError, "Option :method can not be used together with option :const"
  end

  it "prohibits to use with block" do
    expect { described_class.call({method: :foo}, proc {}) }
      .to raise_error Serega::SeregaError, "Option :method can not be used together with block"
  end
end
