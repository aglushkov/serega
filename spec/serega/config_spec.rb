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

  describe "#initialize" do
    it "deeply copies provided opts" do
      opts = {foo: {bar: {bazz: :bazz2}}}

      config = described_class.new(opts)
      expect(config.opts).to eq opts
      expect(config.opts[:foo]).not_to equal opts[:foo]
      expect(config.opts[:foo][:bar]).not_to equal opts[:foo][:bar]
    end
  end

  describe "#[]=" do
    it "adds option" do
      config = described_class.new
      config[:foo] = :bar

      expect(config.opts[:foo]).to eq :bar
    end
  end

  describe "#[]" do
    it "reads option" do
      config = described_class.new
      config[:foo] = :bar

      expect(config[:foo]).to eq :bar
    end
  end
end
