# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::SeregaUtils::CheckOptIsBool do
  def error(key, value)
    "Invalid option #{key.inspect} => #{value.inspect}. Must have a boolean value"
  end

  it "allows only boolean values" do
    expect { described_class.call({many: true}, :many) }.not_to raise_error
    expect { described_class.call({many: false}, :many) }.not_to raise_error
    expect { described_class.call({many: nil}, :many) }.to raise_error Serega::Error, error(:many, nil)
    expect { described_class.call({many: 0}, :many) }.to raise_error Serega::Error, error(:many, 0)
  end
end
