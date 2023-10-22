# frozen_string_literal: true

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch::CheckBatchOptLoader do
  let(:params_count_error) do
    "Invalid :batch option :loader. It must accept 1, 2 or 3 parameters (keys, context, plan)"
  end

  let(:param_type_error) do
    "Option :loader value should not accept keyword argument `a:`"
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

  it "prohibits to add loader with required keyword args" do
    value = proc { |a:| }
    expect { described_class.call(value) }.to raise_error Serega::SeregaError, param_type_error
  end

  it "allows Proc with 1 to 3 args" do
    value = proc {}
    counter = Serega::SeregaUtils::ParamsCount
    allow(counter).to receive(:call).and_return(0, 1, 2, 3, 4)

    expect { described_class.call(value) }.to raise_error Serega::SeregaError, params_count_error
    expect { described_class.call(value) }.not_to raise_error
    expect { described_class.call(value) }.not_to raise_error
    expect { described_class.call(value) }.not_to raise_error
    expect { described_class.call(value) }.to raise_error Serega::SeregaError, params_count_error

    expect(counter).to have_received(:call).with(value, max_count: 3).exactly(5).times
  end

  it "allows symbols" do
    expect { described_class.call(:foo) }.not_to raise_error
  end
end
