# frozen_string_literal: true

load_plugin_code :formatters

RSpec.describe Serega::Plugins::Formatters do
  describe "loading" do
    it "adds empty :formatters config option" do
      serializer = Class.new(Serega) { plugin :formatters }
      expect(serializer.config[:formatters]).to eq({})
    end

    it "adds allowed :format attribute option" do
      serializer = Class.new(Serega) { plugin :formatters }
      expect(serializer.config[:attribute_keys]).to include(:format)
    end
  end

  describe "Attribute methods" do
    let(:serializer) { Class.new(Serega) { plugin :formatters } }

    context "with configured formatter" do
      it "formats result of attribute value" do
        serializer.config[:formatters][:rev] = ->(value) { value.reverse }
        attribute = serializer.attribute(:a, format: :rev) { |obj| obj }

        expect(attribute.value("123", nil)).to eq "321"
        expect(attribute.value([1, 2, 3], nil)).to eq [3, 2, 1]
      end
    end

    context "with block formatter" do
      it "formats result of attribute value" do
        formatter = ->(value) { value.reverse }
        attribute = serializer.attribute(:a, format: formatter) { |obj| obj }

        expect(attribute.value("123", nil)).to eq "321"
        expect(attribute.value([1, 2, 3], nil)).to eq [3, 2, 1]
      end
    end
  end
end
