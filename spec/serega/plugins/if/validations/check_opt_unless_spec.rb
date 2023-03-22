# frozen_string_literal: true

load_plugin_code :if

RSpec.describe Serega::SeregaPlugins::If::CheckOptUnless do
  let(:block_parameters_error) do
    "Invalid attribute option :unless. When it is a Proc it can have maximum two regular parameters (object, context)"
  end

  let(:callable_parameters_error) do
    "Invalid attribute option :unless. When it is a callable object it must have two regular parameters (object, context)"
  end

  let(:must_be_callable) do
    "Invalid attribute option :unless. It must be a Symbol, a Proc or respond to :call"
  end

  it "prohibits non-proc, non-callable, non-symbol values" do
    expect { described_class.call(unless: nil) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(unless: "String") }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(unless: []) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(unless: {}) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(unless: Object) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(unless: Object.new) }.to raise_error Serega::SeregaError, must_be_callable
  end

  it "allows Proc with 0-2 regular args" do
    expect { described_class.call(unless: proc {}) }.not_to raise_error
    expect { described_class.call(unless: proc { |a| }) }.not_to raise_error
    expect { described_class.call(unless: proc { |a, b| }) }.not_to raise_error
    expect { described_class.call(unless: proc { |a, b, c| }) }.to raise_error Serega::SeregaError, block_parameters_error
    expect { described_class.call(unless: proc { |a:| }) }.to raise_error Serega::SeregaError, block_parameters_error
    expect { described_class.call(unless: proc { |*a| }) }.to raise_error Serega::SeregaError, block_parameters_error
  end

  it "allows symbols" do
    expect { described_class.call(unless: :foo) }.not_to raise_error
  end

  it "allows callable value with 2 regular args" do
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
      def self.call(a:, b:, c:)
      end
    }
    callable5 = Class.new {
      def self.call(*a)
      end
    }

    expect { described_class.call(unless: callable0) }.to raise_error Serega::SeregaError, callable_parameters_error
    expect { described_class.call(unless: callable1) }.to raise_error Serega::SeregaError, callable_parameters_error
    expect { described_class.call(unless: callable2) }.not_to raise_error
    expect { described_class.call(unless: callable3) }.to raise_error Serega::SeregaError, callable_parameters_error
    expect { described_class.call(unless: callable4) }.to raise_error Serega::SeregaError, callable_parameters_error
    expect { described_class.call(unless: callable5) }.to raise_error Serega::SeregaError, callable_parameters_error
  end
end
