# frozen_string_literal: true

RSpec.describe Serega::SeregaConfig do
  let(:serializer_class) { Class.new(Serega) }
  let(:config) { serializer_class.config }

  describe ".serializer_class=" do
    it "assigns @serializer_class" do
      config.class.serializer_class = :foo
      expect(config.class.instance_variable_get(:@serializer_class)).to eq :foo
    end
  end

  describe ".serializer_class" do
    it "returns self @serializer_class" do
      expect(config.class.instance_variable_get(:@serializer_class)).to equal serializer_class
      expect(config.class.serializer_class).to equal serializer_class
    end
  end

  describe "#check_initiate_params=" do
    it "validates value is boolean" do
      expect { config.check_initiate_params = false }.not_to raise_error
      expect { config.check_initiate_params = true }.not_to raise_error
      expect { config.check_initiate_params = nil }
        .to raise_error Serega::SeregaError, "Must have boolean value, #{nil.inspect} provided"
    end
  end

  describe "#max_cached_map_per_serializer_count=" do
    it "validates value is boolean" do
      expect { config.max_cached_map_per_serializer_count = 10 }.not_to raise_error
      expect { config.max_cached_map_per_serializer_count = 0 }.not_to raise_error
      expect { config.max_cached_map_per_serializer_count = nil }
        .to raise_error Serega::SeregaError, "Must have Integer value, #{nil.inspect} provided"
    end
  end

  describe "#to_json=" do
    it "sets to_json option" do
      value = proc {}
      config.to_json = value
      expect(config.to_json).to eq value
    end
  end

  describe "#from_json=" do
    it "sets from_json option" do
      value = proc {}
      config.from_json = value
      expect(config.from_json).to eq value
    end
  end
end
