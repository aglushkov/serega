# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Utils::CheckExtraKeywordArg do
  def message(key, value)
    "Option #{key.inspect} value should not accept keyword argument `#{value}:`"
  end

  it "prohibits procs with required keywords" do
    expect { described_class.call(:key, proc {}) }.not_to raise_error
    expect { described_class.call(:key, proc { |one, two = 1, *three, four: 4, **five, &six| }) }.not_to raise_error
    expect { described_class.call(:key, proc { |one:| }) }.to raise_error Serega::SeregaError, message(:key, :one)
    expect { described_class.call(:key, proc { |one, two:| }) }.to raise_error Serega::SeregaError, message(:key, :two)
  end

  it "prohibits lambdas with required keywords" do
    expect { described_class.call(:key, lambda {}) }.not_to raise_error
    expect { described_class.call(:key, lambda { |one, two = 1, *three, four: 4, **five, &six| }) }.not_to raise_error
    expect { described_class.call(:key, lambda { |one:| }) }.to raise_error Serega::SeregaError, message(:key, :one)
    expect { described_class.call(:key, lambda { |one, two:| }) }.to raise_error Serega::SeregaError, message(:key, :two)
  end

  it "prohibits callables with required keywords" do
    callable = Class.new do
      def self.call
      end
    end
    expect { described_class.call(:key, callable) }.not_to raise_error

    callable = Class.new do
      def self.call(one, two, three = 3, *four, five: 1, **six, &seven)
      end
    end
    expect { described_class.call(:key, callable) }.not_to raise_error

    callable = Class.new do
      def self.call(one:)
      end
    end
    expect { described_class.call(:key, callable) }.to raise_error Serega::SeregaError, message(:key, :one)

    callable = Class.new do
      def self.call(one, two:)
      end
    end
    expect { described_class.call(:key, callable) }.to raise_error Serega::SeregaError, message(:key, :two)
  end
end
