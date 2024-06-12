# frozen_string_literal: true

RSpec.describe Serega::SeregaUtils::SymbolName do
  subject(:result) { described_class.call(val) }

  it "converts symbols or non-frozen strings to frozen strings" do
    value = :foo
    result = described_class.call(value)
    expect(result).to eq("foo")
    expect(result).to be_frozen

    value = +"foo"
    result = described_class.call(value)
    expect(result).to eq("foo")
    expect(result).not_to equal(value)
    expect(result).to be_frozen

    value = -"foo"
    result = described_class.call(value)
    expect(result).to equal value
    expect(result).to be_frozen
  end
end
