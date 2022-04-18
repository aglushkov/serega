RSpec.describe Serega::SeregaAttribute::CheckOptKey do
  def error(value)
    "Invalid option :key => #{value.inspect}. Must be a String or a Symbol"
  end

  it "allows only boolean values" do
    expect { described_class.call(key: :foo) }.not_to raise_error
    expect { described_class.call(key: "foo") }.not_to raise_error
    expect { described_class.call(key: nil) }.to raise_error Serega::SeregaError, error(nil)
    expect { described_class.call(key: 123) }.to raise_error Serega::SeregaError, error(123)
  end
end
