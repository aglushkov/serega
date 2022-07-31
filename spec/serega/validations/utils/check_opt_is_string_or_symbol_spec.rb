# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::SeregaUtils::CheckOptIsStringOrSymbol do
  def error(key, value)
    "Invalid option #{key.inspect} => #{value.inspect}. Must be a String or a Symbol"
  end

  it "allows only string or symbol values" do
    expect { described_class.call({foo: "bar"}, :foo) }.not_to raise_error
    expect { described_class.call({foo: :bazz}, :foo) }.not_to raise_error
    expect { described_class.call({foo: 1}, :foo) }.to raise_error error(:foo, 1)
    expect { described_class.call({foo: false}, :foo) }.to raise_error error(:foo, false)
    expect { described_class.call({foo: nil}, :foo) }.to raise_error error(:foo, nil)
    expect { described_class.call({foo: {}}, :foo) }.to raise_error error(:foo, {})
    expect { described_class.call({foo: []}, :foo) }.to raise_error error(:foo, [])
  end
end
