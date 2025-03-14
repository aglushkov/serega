# frozen_string_literal: true

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch::CheckBatchOptIdMethod do
  let(:callable_parameters_error) do
    "Invalid :batch option :id_method. It can accept maximum 2 parameters (object, context)"
  end

  let(:must_be_callable) do
    "Invalid :batch option :id_method. It must be a Symbol, a Proc or respond to #call"
  end

  it "prohibits non-proc, non-callable values" do
    expect { described_class.call(nil) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call("String") }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call([]) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call({}) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(Object) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(Object.new) }.to raise_error Serega::SeregaError, must_be_callable
  end

  it "allows symbols" do
    expect { described_class.call(:foo) }.not_to raise_error
  end

  it "checks callable value params with maximum 2 params" do
    expect { described_class.call(lambda {}) }.not_to raise_error
    expect { described_class.call(lambda { |obj| }) }.not_to raise_error
    expect { described_class.call(lambda { |obj, ctx| }) }.not_to raise_error
    expect { described_class.call(lambda { |obj, ctx, foo| }) }
      .to raise_error Serega::SeregaError, callable_parameters_error
  end
end
