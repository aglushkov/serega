load_plugin_code(:metadata)

RSpec.describe Serega::Plugins::Metadata::MetaAttribute::CheckOpts do
  before do
    allow(Serega::Plugins::Metadata::MetaAttribute::CheckOptHideEmpty).to receive(:call).with(opts)
    allow(Serega::Plugins::Metadata::MetaAttribute::CheckOptHideNil).to receive(:call).with(opts)
  end

  let(:opts) { {opt1: :foo, opt2: :bar} }
  let(:allowed_opts) { %i[opt1 opt2] }

  def invalid_key_error(key, allowed_opts)
    "Invalid option #{key.inspect}. Allowed options are: #{allowed_opts.map(&:inspect).join(", ")}"
  end

  it "checks valid keys" do
    expect { described_class.call(opts, allowed_opts) }.not_to raise_error

    expect { described_class.call(opts, %i[opt1]) }
      .to raise_error Serega::Error, invalid_key_error(:opt2, %i[opt1])
  end

  it "checks each option value" do
    described_class.call(opts, allowed_opts)

    expect(Serega::Plugins::Metadata::MetaAttribute::CheckOptHideEmpty).to have_received(:call).with(opts)
    expect(Serega::Plugins::Metadata::MetaAttribute::CheckOptHideNil).to have_received(:call).with(opts)
  end
end
