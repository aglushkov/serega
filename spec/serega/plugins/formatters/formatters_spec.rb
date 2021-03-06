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
    let(:reverse) { ->(value) { value.reverse } }

    context "with configured formatter" do
      before do
        serializer.config[:formatters][:reverse] = reverse
      end

      it "formats result of attribute value" do
        attribute = serializer.attribute(:a, format: :reverse) { |obj| obj }

        expect(attribute.value("123", nil)).to eq "321"
        expect(attribute.value([1, 2, 3], nil)).to eq [3, 2, 1]
      end

      it "formats result of :const attribute value in advance" do
        attribute = serializer.attribute(:a, const: "123", format: :reverse)
        attribute.value_block # precalculate

        allow(reverse).to receive(:call)
        expect(attribute.value_block.call).to eq "321"
        expect(reverse).not_to have_received(:call)
      end
    end

    context "with block formatter" do
      it "formats result of attribute value" do
        attribute = serializer.attribute(:a, format: reverse) { |obj| obj }

        expect(attribute.value("123", nil)).to eq "321"
        expect(attribute.value([1, 2, 3], nil)).to eq [3, 2, 1]
      end

      it "formats result of :const attribute value in advance" do
        attribute = serializer.attribute(:a, const: "123", format: reverse)
        attribute.value_block # precalculate

        allow(reverse).to receive(:call)
        expect(attribute.value_block.call).to eq "321"
        expect(reverse).not_to have_received(:call)
      end
    end
  end
end
