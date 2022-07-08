# frozen_string_literal: true

RSpec.describe Serega::Attribute::CheckOptMethod do
  def error(value)
    "Invalid option :method => #{value.inspect}. Must be a String or a Symbol"
  end

  it "allows only boolean values" do
    expect { described_class.call(method: :foo) }.not_to raise_error
    expect { described_class.call(method: "foo") }.not_to raise_error
    expect { described_class.call(method: nil) }.to raise_error Serega::Error, error(nil)
    expect { described_class.call(method: 123) }.to raise_error Serega::Error, error(123)
  end
end
