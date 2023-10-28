# frozen_string_literal: true

load_plugin_code :if

RSpec.describe Serega::SeregaPlugins::If::CheckOptIf do
  let(:callable_parameters_error) do
    "Option :if value should have up to 2 parameters (object, context)"
  end

  let(:must_be_callable) do
    "Invalid attribute option :if. It must be a Symbol, a Proc or respond to :call"
  end

  let(:keyword_error) do
    "Invalid :if option. It should not have any required keyword arguments"
  end

  it "prohibits non-proc, non-callable, non-symbol values" do
    expect { described_class.call(if: nil) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(if: "String") }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(if: []) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(if: {}) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(if: Object) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(if: Object.new) }.to raise_error Serega::SeregaError, must_be_callable
  end

  it "checks extra keyword arguments" do
    expect { described_class.call(if: proc { |a:| }) }.to raise_error Serega::SeregaError, keyword_error
  end

  it "checks callable params_count is 0, 1 or 2" do
    value = proc {}
    counter = Serega::SeregaUtils::ParamsCount
    allow(counter).to receive(:call).and_return(0, 1, 2, 3)

    expect { described_class.call(if: value) }.not_to raise_error
    expect { described_class.call(if: value) }.not_to raise_error
    expect { described_class.call(if: value) }.not_to raise_error
    expect { described_class.call(if: value) }.to raise_error Serega::SeregaError, callable_parameters_error

    expect(counter).to have_received(:call).with(value, max_count: 2).exactly(4).times
  end

  it "allows symbols" do
    expect { described_class.call(if: :foo) }.not_to raise_error
  end
end
