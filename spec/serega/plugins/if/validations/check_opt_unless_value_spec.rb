# frozen_string_literal: true

load_plugin_code :if

RSpec.describe Serega::SeregaPlugins::If::CheckOptUnlessValue do
  let(:callable_parameters_error) do
    "Option :unless_value value should have up to 2 parameters (value, context)"
  end

  let(:must_be_callable) do
    "Invalid attribute option :unless_value. It must be a Symbol, a Proc or respond to :call"
  end

  let(:keyword_error) do
    "Option :unless_value value should not accept keyword argument `a:`"
  end

  let(:no_serializer) do
    "Option :unless_value can not be used together with option :serializer"
  end

  it "prohibits to use together with serializer option" do
    expect { described_class.call(unless_value: :foo, serializer: :foo) }.to raise_error Serega::SeregaError, no_serializer
  end

  it "prohibits non-proc, non-callable, non-symbol values" do
    expect { described_class.call(unless_value: nil) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(unless_value: "String") }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(unless_value: []) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(unless_value: {}) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(unless_value: Object) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(unless_value: Object.new) }.to raise_error Serega::SeregaError, must_be_callable
  end

  it "checks extra keyword arguments" do
    expect { described_class.call(unless_value: proc { |a:| }) }.to raise_error Serega::SeregaError, keyword_error
  end

  it "checks callable params_count is 0, 1 or 2" do
    value = proc {}
    counter = Serega::SeregaUtils::ParamsCount
    allow(counter).to receive(:call).and_return(0, 1, 2, 3)

    expect { described_class.call(unless_value: value) }.not_to raise_error
    expect { described_class.call(unless_value: value) }.not_to raise_error
    expect { described_class.call(unless_value: value) }.not_to raise_error
    expect { described_class.call(unless_value: value) }.to raise_error Serega::SeregaError, callable_parameters_error

    expect(counter).to have_received(:call).with(value, max_count: 2).exactly(4).times
  end

  it "allows symbols" do
    expect { described_class.call(unless_value: :foo) }.not_to raise_error
  end
end
