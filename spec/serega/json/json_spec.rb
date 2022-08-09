# frozen_string_literal: true

RSpec.describe Serega::SeregaJSON do
  describe described_class::JSONDump do
    it "dumps object to json" do
      expect(described_class.call({foo: :bar})).to eq '{"foo":"bar"}'
    end
  end

  describe described_class::JSONLoad do
    it "loads objects from json" do
      expect(described_class.call('{"foo":"bar"}')).to eq("foo" => "bar")
    end
  end
end
