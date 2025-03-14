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

  it "checks it has maximum 2 params" do
    expect { described_class.call(value: lambda {}) }.not_to raise_error
    expect { described_class.call(value: lambda { |obj| }) }.not_to raise_error
    expect { described_class.call(value: lambda { |obj, ctx| }) }.not_to raise_error
    expect { described_class.call(value: lambda { |obj, ctx, foo| }) }
      .to raise_error Serega::SeregaError, params_count_error
  end

  it "checks keyword value" do
    expect { described_class.call({value: :value}) }
      .to raise_error Serega::SeregaError, type_error
  end
end
