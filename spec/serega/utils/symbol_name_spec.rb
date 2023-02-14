# frozen_string_literal: true

RSpec.describe Serega::SeregaUtils::SymbolName do
  subject(:result) { described_class.call(val) }

  let(:val) { :foo }

  it "returns frozen string" do
    expect(result).to eq("foo")
    expect(result).to be_frozen
  end
end
