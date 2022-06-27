require "bigdecimal"
require "json"

RSpec.describe Serega::Utils::ToJSON do
  def to_json(data)
    described_class.call(data)
  end

  def real_json(data)
    JSON.dump(data)
  end

  describe "transforming different data types" do
    it "transforms data to json" do
      expect(to_json(nil)).to eq(real_json(nil))
      expect(to_json(true)).to eq(real_json(true))
      expect(to_json(false)).to eq(real_json(false))
      expect(to_json(:abc)).to eq(real_json(:abc))
      expect(to_json("abc")).to eq(real_json("abc"))
      expect(to_json(1.23)).to eq(real_json(1.23))
      expect(to_json(1)).to eq(real_json(1))
      expect(to_json([])).to eq(real_json([]))
      expect(to_json({})).to eq(real_json({}))
      expect(to_json(BigDecimal("1"))).to eq(real_json(BigDecimal("1")))
    end
  end

  describe "transforming nested hashes" do
    it "transforms data to json" do
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
      expect(to_json(data)).to eq real_json(data)
    end
  end
end
