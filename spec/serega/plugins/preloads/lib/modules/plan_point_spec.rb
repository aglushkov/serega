# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::SeregaPlugins::Preloads do
  let(:serializer_class) { Class.new(Serega) { plugin :preloads } }

  describe "PlanPointMethods" do
    def plan_point(attribute, modifiers = nil)
      attribute.class.serializer_class::SeregaPlanPoint.new("plan", attribute, modifiers)
    end

    it "delegates #preloads_path to attribute" do
      attribute = serializer_class.attribute :foo, preload: :bar
      expect(attribute.preloads).to eq(bar: {})

      point = plan_point(attribute)
      expect(point.preloads_path).to eq([:bar])
    end

    it "constructs #preloads for all nested preloads" do
      foo = serializer_class.attribute :foo, preload: :foo1, serializer: serializer_class, hide: true
      serializer_class.attribute :bar, preload: :bar1, serializer: serializer_class, hide: true

      point = plan_point(foo)
      expect(point.preloads).to eq({})

      point = plan_point(foo, {with: {foo: {}}})
      expect(point.preloads).to eq({foo1: {}})

      point = plan_point(foo, {with: {foo: {}, bar: {}}})
      expect(point.preloads).to eq({foo1: {}, bar1: {}})

      point = plan_point(foo, {with: {foo: {}, bar: {foo: {}}}})
      expect(point.preloads).to eq({foo1: {}, bar1: {foo1: {}}})
    end
  end
end
