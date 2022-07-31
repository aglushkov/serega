# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckOptHide do
  def error(value)
    "Invalid option :hide => #{value.inspect}. Must have a boolean value"
  end

  it "allows only boolean values" do
    expect { described_class.call(hide: true) }.not_to raise_error
    expect { described_class.call(hide: false) }.not_to raise_error
    expect { described_class.call(hide: nil) }.to raise_error Serega::SeregaError, error(nil)
    expect { described_class.call(hide: 0) }.to raise_error Serega::SeregaError, error(0)
  end
end
