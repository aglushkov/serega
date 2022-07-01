RSpec.describe Serega::Attribute::CheckOpts do
  before do
    allow(Serega::Attribute::CheckOptHide).to receive(:call).with(opts)
    allow(Serega::Attribute::CheckOptKey).to receive(:call).with(opts)
    allow(Serega::Attribute::CheckOptMany).to receive(:call).with(opts)
    allow(Serega::Attribute::CheckOptSerializer).to receive(:call).with(opts)
  end

  let(:opts) { {opt1: :foo, opt2: :bar} }
  let(:attribute_keys) { %i[opt1 opt2] }

  def invalid_key_error(key, attribute_keys)
    "Invalid option #{key.inspect}. Allowed options are: #{attribute_keys.map(&:inspect).join(", ")}"
  end

  it "checks valid keys" do
    expect { described_class.call(opts, attribute_keys) }.not_to raise_error

    expect { described_class.call(opts, %i[opt1]) }
      .to raise_error Serega::Error, invalid_key_error(:opt2, %i[opt1])
  end

  it "checks each option value" do
    described_class.call(opts, attribute_keys)

    expect(Serega::Attribute::CheckOptHide).to have_received(:call).with(opts)
    expect(Serega::Attribute::CheckOptKey).to have_received(:call).with(opts)
    expect(Serega::Attribute::CheckOptMany).to have_received(:call).with(opts)
    expect(Serega::Attribute::CheckOptSerializer).to have_received(:call).with(opts)
  end
end
