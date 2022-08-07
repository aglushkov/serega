# frozen_string_literal: true

require "bigdecimal"
require "json"

RSpec.describe Serega::SeregaUtils::JSON do
  def dump(data)
    described_class.dump(data)
  end

  def load(data)
    described_class.load(data)
  end

  def real_json(data)
    JSON.dump(data)
  end

  describe "#dump" do
    it "transforms data to json" do
      expect(dump(nil)).to eq(real_json(nil))
      expect(dump(true)).to eq(real_json(true))
      expect(dump(false)).to eq(real_json(false))
      expect(dump(:abc)).to eq(real_json(:abc))
      expect(dump("abc")).to eq(real_json("abc"))
      expect(dump(1.23)).to eq(real_json(1.23))
      expect(dump(1)).to eq(real_json(1))
      expect(dump([])).to eq(real_json([]))
      expect(dump({})).to eq(real_json({}))
      expect(dump(BigDecimal("1"))).to eq(real_json(BigDecimal("1")))
    end

    it "transforms nested hashes" do
      data = {
        data: {
          a1: "1",
          a2: 2,
          a3: 3.0,
          a4: 4.44,
          a5: BigDecimal("5.5555555555555555555555"),
          a6: [nil, true, false, [1, 2, 3]]
        }
      }
      expect(dump(data)).to eq real_json(data)
    end
  end

  describe "#load" do
    it "loads data from json string" do
      expect(load('{"foo": "bar"}')).to eq({"foo" => "bar"})
    end
  end
end
