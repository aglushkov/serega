# frozen_string_literal: true

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch::CheckBatchOptLoader do
  let(:block_parameters_error) do
    "Invalid :batch option :loader. When it is a Proc it can have maximum three regular parameters (keys, context, point)"
  end

  let(:callable_parameters_error) do
    "Invalid :batch option :loader. When it is a callable object it must have three regular parameters (keys, context, point)"
  end

  let(:must_be_callable) do
    "Invalid :batch option :loader. It must be a Symbol, a Proc or respond to :call"
  end

  it "prohibits non-proc, non-callable values" do
    expect { described_class.call(nil) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call("String") }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call([]) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call({}) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(Object) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(Object.new) }.to raise_error Serega::SeregaError, must_be_callable
  end

  it "allows Proc with 0-3 regular args" do
    expect { described_class.call(proc {}) }.not_to raise_error
    expect { described_class.call(proc { |a| }) }.not_to raise_error
    expect { described_class.call(proc { |a, b| }) }.not_to raise_error
    expect { described_class.call(proc { |a, b, c| }) }.not_to raise_error
    expect { described_class.call(proc { |a, b, c, d| }) }.to raise_error Serega::SeregaError, block_parameters_error
    expect { described_class.call(proc { |a:| }) }.to raise_error Serega::SeregaError, block_parameters_error
    expect { described_class.call(proc { |*a| }) }.to raise_error Serega::SeregaError, block_parameters_error
  end

  it "allows symbols" do
    expect { described_class.call(:foo) }.not_to raise_error
  end

  it "allows callable value with 3 regular args" do
    callable0 = Class.new {
      def self.call
      end
    }
    callable1 = Class.new {
      def self.call(a)
      end
    }
    callable2 = Class.new {
      def self.call(a, b)
      end
    }
    callable3 = Class.new {
      def self.call(a, b, c)
      end
    }
    callable4 = Class.new {
      def self.call(a, b, c, d)
      end
    }
    callable5 = Class.new {
      def self.call(a:, b:, c:)
      end
    }
    callable6 = Class.new {
      def self.call(*a)
      end
    }

    expect { described_class.call(callable0) }.to raise_error Serega::SeregaError, callable_parameters_error
    expect { described_class.call(callable1) }.to raise_error Serega::SeregaError, callable_parameters_error
    expect { described_class.call(callable2) }.to raise_error Serega::SeregaError, callable_parameters_error
    expect { described_class.call(callable3) }.not_to raise_error
    expect { described_class.call(callable4) }.to raise_error Serega::SeregaError, callable_parameters_error
    expect { described_class.call(callable5) }.to raise_error Serega::SeregaError, callable_parameters_error
    expect { described_class.call(callable6) }.to raise_error Serega::SeregaError, callable_parameters_error
  end
end
