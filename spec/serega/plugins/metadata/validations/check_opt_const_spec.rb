# frozen_string_literal: true

load_plugin_code(:root, :metadata)

RSpec.describe Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOptConst do
  it "prohibits to use with :value opt" do
    expect { described_class.call(const: :foo, value: -> {}) }
      .to raise_error Serega::SeregaError, "Option :const can not be used together with option :value"
  end

  it "prohibits to use with block" do
    expect { described_class.call({const: :foo}, proc {}) }
      .to raise_error Serega::SeregaError, "Option :const can not be used together with block"
  end

  it "allows no :const option" do
    expect { described_class.call({}, proc {}) }.not_to raise_error
  end
end
