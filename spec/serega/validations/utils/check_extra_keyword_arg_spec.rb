# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Utils::CheckExtraKeywordArg do
  def message(key, value)
    "Invalid #{key}. It should not have any required keyword arguments"
  end

  it "prohibits procs with required keywords" do
    expect { described_class.call(proc {}, :key) }.not_to raise_error
    expect { described_class.call(proc { |one, two = 1, *three, four: 4, **five, &six| }, :key) }.not_to raise_error
    expect { described_class.call(proc { |one:| }, :key) }.to raise_error Serega::SeregaError, message(:key, :one)
    expect { described_class.call(proc { |one, two:| }, :key) }.to raise_error Serega::SeregaError, message(:key, :two)
  end

  it "prohibits lambdas with required keywords" do
    expect { described_class.call(lambda {}, :key) }.not_to raise_error
    expect { described_class.call(lambda { |one, two = 1, *three, four: 4, **five, &six| }, :key) }.not_to raise_error
    expect { described_class.call(lambda { |one:| }, :key) }.to raise_error Serega::SeregaError, message(:key, :one)
    expect { described_class.call(lambda { |one, two:| }, :key) }.to raise_error Serega::SeregaError, message(:key, :two)
  end

  it "prohibits callables with required keywords" do
    callable = Class.new do
      def self.call
      end
    end
    expect { described_class.call(callable, :key) }.not_to raise_error

    callable = Class.new do
      def self.call(one, two, three = 3, *four, five: 1, **six, &seven)
      end
    end
    expect { described_class.call(callable, :key) }.not_to raise_error

    callable = Class.new do
      def self.call(one:)
      end
    end
    expect { described_class.call(callable, :key) }.to raise_error Serega::SeregaError, message(:key, :one)

    callable = Class.new do
      def self.call(one, two:)
      end
    end
    expect { described_class.call(callable, :key) }.to raise_error Serega::SeregaError, message(:key, :two)
  end
end
