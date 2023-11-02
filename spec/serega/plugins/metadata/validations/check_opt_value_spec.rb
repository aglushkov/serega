# frozen_string_literal: true

load_plugin_code(:root, :metadata)

RSpec.describe Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOptValue do
  let(:opts) { {} }

  let(:type_error) { "Option :value value must be a Proc or respond to #call" }
  let(:params_count_error) { "Option :value value can have maximum 2 parameters (object(s), context)" }

  it "prohibits to use with :const opt" do
    expect { described_class.call(value: -> {}, const: :foo) }
      .to raise_error Serega::SeregaError, "Option :value can not be used together with option :const"
  end

  it "prohibits to use with block" do
    expect { described_class.call({value: -> {}}, proc {}) }
      .to raise_error Serega::SeregaError, "Option :value can not be used together with block"
  end

  it "allows no :value option" do
    expect { described_class.call({}, proc {}) }.not_to raise_error
  end

  it "prohibits to use keyword as value" do
    validator = Serega::SeregaValidations::Utils::CheckExtraKeywordArg
    allow(validator).to receive(:call)

    value = proc { |one| }
    described_class.call(value: value)
    expect(validator).to have_received(:call).with(value, ":value option")
  end

  it "checks it has maximum 2 params" do
    value = proc { |one| }
    counter = Serega::SeregaUtils::ParamsCount
    allow(counter).to receive(:call).and_return(0, 1, 2, 3)

    expect { described_class.call(value: value) }.not_to raise_error
    expect { described_class.call(value: value) }.not_to raise_error
    expect { described_class.call(value: value) }.not_to raise_error
    expect { described_class.call(value: value) }.to raise_error Serega::SeregaError, params_count_error

    expect(counter).to have_received(:call).with(value, max_count: 2).exactly(4).times
  end

  it "checks keyword value" do
    expect { described_class.call({value: :value}) }
      .to raise_error Serega::SeregaError, type_error
  end
end
