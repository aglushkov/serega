# frozen_string_literal: true

RSpec.describe Serega::SeregaJSON do
  before { described_class.instance_variable_set(:@adapter, nil) }

  after { described_class.instance_variable_set(:@adapter, nil) }

  it "returns :json adapter by default" do
    expect(described_class.adapter).to eq :json
  end

  it "returns :oj adapter if Oj defined" do
    stub_const("Oj", 1)
    expect(described_class.adapter).to eq :oj
  end
end
