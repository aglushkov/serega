# frozen_string_literal: true

load_plugin_code :presenter

RSpec.describe Serega::Plugins::Presenter do
  let(:serializer) { Class.new(Serega) { plugin :presenter } }

  describe "loading" do
    it "adds serializer::Presenter class" do
      expect(serializer::Presenter).to be_a Class
    end
  end

  describe ".inherited" do
    let(:parent) { serializer }

    it "inherits Presenter class" do
      child = Class.new(parent)
      expect(parent::Presenter).to be child::Presenter.superclass
    end
  end

  it "adds presenter methods when adding attribute" do
    serializer.attribute :length
    expect(serializer::Presenter.instance_methods).to include(:length)
  end

  it "adds presenter methods when adding attribute with key" do
    serializer.attribute :length, key: :size
    expect(serializer::Presenter.instance_methods).to include(:size)
  end

  it "does not add presenter methods when adding attribute with block" do
    serializer.attribute(:length) {}
    expect(serializer::Presenter.instance_methods).not_to include(:length)
  end

  it "adds presenter methods used in block after first serialization" do
    serializer.attribute(:length) { |obj| obj.size }

    expect(serializer::Presenter.instance_methods).not_to include(:size)
    serializer.new.to_h("")
    expect(serializer::Presenter.instance_methods).to include(:size)
  end

  it "allows to use custom methods defined directly in Presenter class" do
    serializer::Presenter.class_exec do
      def rev
        reverse
      end
    end

    serializer.attribute(:rev) { |obj| obj.rev }
    rev = serializer.new.to_h("123")[:rev]
    expect("321").to eq rev
  end

  it "allows to override attribute methods" do
    serializer.attribute :value

    expect(serializer::Presenter.instance_methods).to include(:value)
    serializer::Presenter.class_exec do
      def value
        "VALUE"
      end
    end

    res = serializer.new.to_h(nil)
    value = res[:value]
    expect("VALUE").to eq value
  end
end
