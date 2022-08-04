# frozen_string_literal: true

RSpec.describe Serega::SeregaMap do
  let(:base_class) { Class.new(Serega) }
  let(:current_serializer) { a }
  let(:described_class) { current_serializer::SeregaMap }

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

  def map(opts)
    current_serializer::SeregaMap.call(opts)
  end

  describe ".call" do
    it "returns all not hidden attributes by default" do
      result = map({})
      expected_result = [
        [a.attributes[:a1], []],
        [a.attributes[:a2], []],
        [a.attributes[:d], [
          [d.attributes[:d1], []],
          [d.attributes[:d2], []]
        ]]
      ]

      expect(result).to eq expected_result
    end

    it "returns only attributes from :only option" do
      result = map(only: {a2: {}, d: {d1: {}}}, except: {}, with: {})
      expected_result = [
        [a.attributes[:a2], []],
        [a.attributes[:d], [
          [d.attributes[:d1], []]
        ]]
      ]

      expect(result).to eq expected_result
    end

    it "returns all not hidden attributes except provided in :except option" do
      result = map(only: {}, except: {a2: {}, d: {d1: {}}}, with: {})
      expected_result = [
        [a.attributes[:a1], []],
        [a.attributes[:d], [
          [d.attributes[:d2], []]
        ]]
      ]

      expect(result).to eq expected_result
    end

    it "returns all not hidden attributes and attributes defined in :with option" do
      result = map(only: {}, except: {}, with: {a3: {}, b: {}, c: {c3: {}}})
      expected_result = [
        [a.attributes[:a1], []],
        [a.attributes[:a2], []],
        [a.attributes[:a3], []],
        [a.attributes[:b], [
          [b.attributes[:b1], []],
          [b.attributes[:b2], []]
        ]],
        [a.attributes[:c], [
          [c.attributes[:c1], []],
          [c.attributes[:c2], []],
          [c.attributes[:c3], []]
        ]],
        [a.attributes[:d], [
          [d.attributes[:d1], []],
          [d.attributes[:d2], []]
        ]]
      ]

      expect(result).to eq expected_result
    end
  end

  describe "saving maps to cache" do
    it "does not save maps to cache when not configured to do so" do
      result1 = map(only: {a1: {}})
      result2 = map(only: {a1: {}})

      expect(result1).to eq [[a.attributes[:a1], []]]
      expect(result2).to eq [[a.attributes[:a1], []]]
      expect(result1).not_to equal result2
    end

    it "saves maps to cache and uses them when configured to use cache" do
      current_serializer.config[:max_cached_map_per_serializer_count] = 1
      result1 = map(only: {a1: {}})
      result2 = map(only: {a1: {}})

      expect(result1).to eq [[a.attributes[:a1], []]]
      expect(result2).to eq [[a.attributes[:a1], []]]
      expect(result1).to equal result2
    end

    it "removes from cache oldest maps if cached keys count more than configured" do
      current_serializer.config[:max_cached_map_per_serializer_count] = 1

      result1 = map(only: {a1: {}})
      map(only: {a2: {}}) # replace cached result1

      result2 = map(only: {a1: {}})

      expect(result1).to eq [[a.attributes[:a1], []]]
      expect(result2).to eq [[a.attributes[:a1], []]]
      expect(result1).not_to equal result2
    end
  end
end
