# frozen_string_literal: true

load_plugin_code :formatters

RSpec.describe Serega::SeregaPlugins::Formatters do
  describe "loading" do
    let(:serializer) { Class.new(Serega) }

    it "adds empty :formatters config option" do
      serializer.plugin :formatters
      expect(serializer.config.formatters.opts).to eq({})
    end

    it "adds allowed :format attribute option" do
      serializer.plugin :formatters
      expect(serializer.config.attribute_keys).to include(:format)
    end

    it "allows to provide formatters when loading plugin" do
      serializer.plugin :formatters, formatters: {foo: :bar}
      expect(serializer.config.formatters.opts).to eq({foo: :bar})
    end

    it "raises error if loaded after :batch plugin" do
      error = "Plugin `formatters` must be loaded before `batch`"
      serializer.plugin :batch
      expect { serializer.plugin(:formatters) }.to raise_error Serega::SeregaError, error
    end
  end

  describe "configuration" do
    let(:serializer) { Class.new(Serega) { plugin :formatters } }

    it "preserves formatters" do
      formatters1 = serializer.config.formatters
      formatters2 = serializer.config.formatters
      expect(formatters1).to be formatters2
    end

    it "allows to add formatters" do
      serializer.config.formatters.add({foo: :bar})
      expect(serializer.config.formatters.opts).to eq({foo: :bar})
    end
  end

  describe "Attribute methods" do
    let(:serializer) { Class.new(Serega) { plugin :formatters } }
    let(:reverse) { ->(value) { value.reverse } }

    context "with configured formatter" do
      before do
        serializer.config.formatters.add(reverse: reverse)
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

      it "returns regular block when no format option specified" do
        attribute = serializer.attribute(:a) { |obj| obj }
        expect(attribute.value("123", nil)).to eq "123"
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
