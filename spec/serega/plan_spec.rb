# frozen_string_literal: true

RSpec.describe Serega::SeregaPlan do
  let(:base_class) { Class.new(Serega) }
  let(:a) do
    ser = Class.new(base_class)

    ser.attribute :a1
    ser.attribute :a2
    ser.attribute :a3, hide: true

    ser.attribute :b, serializer: b, hide: true
    ser.attribute :c, serializer: c, hide: true
    ser.attribute :d, serializer: d
    ser
  end
  let(:b) do
    ser = Class.new(base_class)
    ser.attribute :b1
    ser.attribute :b2
    ser.attribute :b3, hide: true
    ser
  end
  let(:c) do
    ser = Class.new(base_class)
    ser.attribute :c1
    ser.attribute :c2
    ser.attribute :c3, hide: true
    ser
  end
  let(:d) do
    ser = Class.new(base_class)
    ser.attribute :d1
    ser.attribute :d2
    ser.attribute :d3, hide: true
    ser
  end
  let(:current_serializer) { a }
  let(:described_class) { current_serializer::SeregaPlan }

  def plan(opts)
    current_serializer::SeregaPlan.call(opts)
  end

  def satisfy_attribute_names(names)
    satisfy do |result|
      expect(result.points.count).to eq names.count

      names.each do |key, child_keys|
        point = result.points.find { |point| point.name == key }
        expect(point).not_to be_nil
        expect(point.child_plan).to satisfy_attribute_names(child_keys) if child_keys
      end
    end
  end

  describe ".call" do
    it "returns plan with all not hidden attributes by default" do
      result = plan({})

      expect(result).to satisfy_attribute_names(
        a1: nil,
        a2: nil,
        d: {d1: nil, d2: nil}
      )
    end

    it "returns only attributes from :only option" do
      result = plan(only: {a2: {}, d: {d1: {}}}, except: {}, with: {})

      expect(result).to satisfy_attribute_names(
        a2: nil,
        d: {d1: nil}
      )
    end

    it "returns all not hidden attributes except provided in :except option" do
      result = plan(only: {}, except: {a2: {}, d: {d1: {}}}, with: {})

      expect(result).to satisfy_attribute_names(
        a1: nil,
        d: {d2: nil}
      )
    end

    it "returns all not hidden attributes and attributes defined in :with option" do
      result = plan(only: {}, except: {}, with: {a3: {}, b: {}, c: {c3: {}}})

      expect(result).to satisfy_attribute_names(
        a1: nil,
        a2: nil,
        a3: nil,
        b: {b1: nil, b2: nil},
        c: {c1: nil, c2: nil, c3: nil},
        d: {d1: nil, d2: nil}
      )
    end
  end

  describe "saving plans to cache" do
    it "does not save plans to cache when not configured to do so" do
      result1 = plan(only: {a1: {}})
      result2 = plan(only: {a1: {}})

      expect(result1).to satisfy_attribute_names(a1: nil)
      expect(result2).to satisfy_attribute_names(a1: nil)
      expect(result1).not_to equal result2
    end

    it "saves plans to cache and uses them when configured to use cache" do
      current_serializer.config.max_cached_plans_per_serializer_count = 1
      result1 = plan(only: {a1: {}})
      result2 = plan(only: {a1: {}})

      expect(result1).to satisfy_attribute_names(a1: nil)
      expect(result2).to satisfy_attribute_names(a1: nil)
      expect(result1).to equal result2
    end

    it "removes from cache oldest plans if cached keys count more than configured" do
      current_serializer.config.max_cached_plans_per_serializer_count = 1

      result1 = plan(only: {a1: {}})
      plan(only: {a2: {}}) # replace cached result1

      result2 = plan(only: {a1: {}})

      expect(result1).to satisfy_attribute_names(a1: nil)
      expect(result2).to satisfy_attribute_names(a1: nil)
      expect(result1).not_to equal result2
    end
  end
end
