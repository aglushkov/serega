# frozen_string_literal: true

require "bigdecimal"
require "json"

RSpec.describe Serega::Utils::AsJSON do
  def as_json(data)
    described_class.call(data, to_json: JSON.method(:dump))
  end

  def from_json(data)
    JSON.parse(JSON.dump(data))
  end

  describe "transforming different data types" do
    let(:time) { Time.now }
    let(:big) { BigDecimal("1") }

    it "transforms data to json compatible types" do
      expect(as_json(nil)).to eq(from_json(nil))
      expect(as_json(true)).to eq(from_json(true))
      expect(as_json(false)).to eq(from_json(false))
      expect(as_json(:abc)).to eq(from_json(:abc))
      expect(as_json("abc")).to eq(from_json("abc"))
      expect(as_json(1.23)).to eq(from_json(1.23))
      expect(as_json(1)).to eq(from_json(1))
      expect(as_json([])).to eq(from_json([]))
      expect(as_json({})).to eq(from_json({}))
      expect(as_json(big)).to eq(from_json(big))
      expect(as_json(time)).to eq(from_json(time))
    end
  end

  describe "transforming nested hashes and arrays" do
    it "transforms data to json compatible types" do
      data = {
        data: {
          a0: :a0,
          a1: "1",
          a2: 2,
          a3: 3.0,
          a4: 4.44,
          a5: BigDecimal("5.5555555555555555555555"),
          a6: [nil, true, false, [1, 2, 3, Time.now]]
        }
      }
      expect(as_json(data)).to eq(from_json(data))
    end
  end
end
