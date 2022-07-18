# frozen_string_literal: true

RSpec.describe Serega::Validations::Attribute::CheckOptMany do
  def error(value)
    "Invalid option :many => #{value.inspect}. Must have a boolean value"
  end

  it "allows only boolean values" do
    expect { described_class.call(many: true) }.not_to raise_error
    expect { described_class.call(many: false) }.not_to raise_error
    expect { described_class.call(many: nil) }.to raise_error Serega::Error, error(nil)
    expect { described_class.call(many: 0) }.to raise_error Serega::Error, error(0)
  end
end
