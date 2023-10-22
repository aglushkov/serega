# frozen_string_literal: true

RSpec.describe Serega::SeregaUtils::ParamsCount do
  it "counts regular parameters of proc" do
    callable = proc {}
    expect(described_class.call(callable, max_count: 1)).to eq 0

    callable = proc { |one| }
    expect(described_class.call(callable, max_count: 0)).to eq 0
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 1

    callable = proc { |*one| }
    expect(described_class.call(callable, max_count: 0)).to eq 0
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2

    callable = proc { |one, two = 2| }
    expect(described_class.call(callable, max_count: 0)).to eq 0
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2
    expect(described_class.call(callable, max_count: 3)).to eq 2

    callable = proc { |one, *two| }
    expect(described_class.call(callable, max_count: 0)).to eq 0
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2
    expect(described_class.call(callable, max_count: 3)).to eq 3

    callable = proc { |one, two = 2, *three| }
    expect(described_class.call(callable, max_count: 0)).to eq 0
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2
    expect(described_class.call(callable, max_count: 3)).to eq 3
    expect(described_class.call(callable, max_count: 4)).to eq 4

    callable = proc { |one:, two: 2, **three, &block| }
    expect(described_class.call(callable, max_count: 5)).to eq 0
  end

  it "counts regular parameters of lambdas" do
    callable = lambda {}
    expect(described_class.call(callable, max_count: 1)).to eq 0

    callable = lambda { |one| }
    expect(described_class.call(callable, max_count: 0)).to eq 1
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 1

    callable = lambda { |*one| }
    expect(described_class.call(callable, max_count: 0)).to eq 0
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2

    callable = lambda { |one, two = 2| }
    expect(described_class.call(callable, max_count: 0)).to eq 1
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2
    expect(described_class.call(callable, max_count: 3)).to eq 2

    callable = lambda { |one, *two| }
    expect(described_class.call(callable, max_count: 0)).to eq 1
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2
    expect(described_class.call(callable, max_count: 3)).to eq 3

    callable = lambda { |one, two = 2, *three| }
    expect(described_class.call(callable, max_count: 0)).to eq 1
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2
    expect(described_class.call(callable, max_count: 3)).to eq 3
    expect(described_class.call(callable, max_count: 4)).to eq 4

    callable = lambda { |one:, two: 2, **three, &block| }
    expect(described_class.call(callable, max_count: 5)).to eq 0
  end

  it "counts regular parameters of callable values" do
    callable = Class.new do
      def self.call
      end
    end
    expect(described_class.call(callable, max_count: 1)).to eq 0

    callable = Class.new do
      def self.call(one)
      end
    end
    expect(described_class.call(callable, max_count: 0)).to eq 1
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 1

    callable = Class.new do
      def self.call(*one)
      end
    end
    expect(described_class.call(callable, max_count: 0)).to eq 0
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2

    callable = Class.new do
      def self.call(one, two = 2)
      end
    end
    expect(described_class.call(callable, max_count: 0)).to eq 1
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2
    expect(described_class.call(callable, max_count: 3)).to eq 2

    callable = Class.new do
      def self.call(one, *two)
      end
    end
    expect(described_class.call(callable, max_count: 0)).to eq 1
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2
    expect(described_class.call(callable, max_count: 3)).to eq 3

    callable = Class.new do
      def self.call(one, two = 2, *three)
      end
    end
    expect(described_class.call(callable, max_count: 0)).to eq 1
    expect(described_class.call(callable, max_count: 1)).to eq 1
    expect(described_class.call(callable, max_count: 2)).to eq 2
    expect(described_class.call(callable, max_count: 3)).to eq 3
    expect(described_class.call(callable, max_count: 4)).to eq 4

    callable = Class.new do
      def self.call(one:, two: 2, **three, &block)
      end
    end
    expect(described_class.call(callable, max_count: 5)).to eq 0
  end

  it "returns 1 if provided callable with not named *rest parameters" do
    callable = :one?.to_proc
    expect(described_class.call(callable, max_count: 2)).to eq 1

    callable = :one?.to_proc.method(:call)
    expect(described_class.call(callable, max_count: 2)).to eq 1
  end
end
