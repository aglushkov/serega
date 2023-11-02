# frozen_string_literal: true

load_plugin_code(:root, :metadata)

RSpec.describe Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOpts do
  def invalid_key_error(key, allowed_keys)
    "Invalid option #{key.inspect}. Allowed options are: #{allowed_keys.map(&:inspect).join(", ")}"
  end

  let(:opts) { {opt1: :foo, opt2: :bar} }
  let(:block) { proc {} }
  let(:allowed_keys) { %i[opt1 opt2] }

  describe "checking valid options keys" do
    it "checks valid keys" do
      expect { described_class.call(opts, block, allowed_keys) }.not_to raise_error

      expect { described_class.call(opts, block, %i[opt1]) }
        .to raise_error Serega::SeregaError, invalid_key_error(:opt2, %i[opt1])
    end
  end

  describe "checking each option" do
    before do
      allow(Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOptConst).to receive(:call)
      allow(Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOptHideEmpty).to receive(:call).with(opts)
      allow(Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOptHideNil).to receive(:call).with(opts)
      allow(Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOptValue).to receive(:call).with(opts, block)
    end

    it "checks each option value" do
      described_class.call(opts, block, allowed_keys)

      expect(Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOptConst).to have_received(:call).with(opts, block)
      expect(Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOptHideEmpty).to have_received(:call).with(opts)
      expect(Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOptHideNil).to have_received(:call).with(opts)
      expect(Serega::SeregaPlugins::Metadata::MetaAttribute::CheckOptValue).to have_received(:call).with(opts, block)
    end
  end

  it "checks any value is provided - :const, :value or block" do
    expect { described_class.call({const: 1}, nil, [:const]) }.not_to raise_error
    expect { described_class.call({value: proc {}}, nil, [:value]) }.not_to raise_error
    expect { described_class.call({foo: :bar}, block, [:foo]) }.not_to raise_error
    expect { described_class.call({foo: :bar}, nil, [:foo]) }
      .to raise_error Serega::SeregaError, "Please provide block argument or add :value or :const option"
  end
end
