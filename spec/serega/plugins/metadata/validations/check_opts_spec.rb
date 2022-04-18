load_plugin_code(:metadata)

RSpec.describe Serega::SeregaPlugins::Metadata::SeregaMetaAttribute::CheckOpts do
  before do
    allow(Serega::SeregaPlugins::Metadata::SeregaMetaAttribute::CheckOptHideEmpty).to receive(:call).with(opts)
    allow(Serega::SeregaPlugins::Metadata::SeregaMetaAttribute::CheckOptHideNil).to receive(:call).with(opts)
  end

  let(:opts) { {opt1: :foo, opt2: :bar} }
  let(:allowed_opts) { %i[opt1 opt2] }

  def invalid_key_error(key, allowed_opts)
    "Invalid option #{key.inspect}. Allowed options are: #{allowed_opts.map(&:inspect).join(", ")}"
  end

  it "checks valid keys" do
    expect { described_class.call(opts, allowed_opts) }.not_to raise_error

    expect { described_class.call(opts, %i[opt1]) }
      .to raise_error Serega::SeregaError, invalid_key_error(:opt2, %i[opt1])
  end

  it "checks each option value" do
    described_class.call(opts, allowed_opts)

    expect(Serega::SeregaPlugins::Metadata::SeregaMetaAttribute::CheckOptHideEmpty).to have_received(:call).with(opts)
    expect(Serega::SeregaPlugins::Metadata::SeregaMetaAttribute::CheckOptHideNil).to have_received(:call).with(opts)
  end
end
