# frozen_string_literal: true

require "./lib/serega/json/oj"

RSpec.describe Serega::SeregaJSON do
  before { stub_const("Oj", oj) }

  describe described_class::OjDump do
    let(:oj) { double(dump: "stubbed_response") }

    it "dumps object to json with mode: :compat" do
      expect(described_class.call("OBJ")).to eq "stubbed_response"
      expect(oj).to have_received(:dump).with("OBJ", mode: :compat)
    end
  end

  describe described_class::OjLoad do
    let(:oj) { double(load: "loaded_response") }

    it "loads objects from json" do
      expect(described_class.call("OBJ")).to eq "loaded_response"
      expect(oj).to have_received(:load).with("OBJ")
    end
  end
end
