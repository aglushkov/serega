load_plugin_code(:metadata)

RSpec.describe Serega::Plugins::Metadata::MetaAttribute::CheckOptHideNil do
  def error(value)
    "Invalid option :hide_nil => #{value.inspect}. Must be true"
  end

  it "allows only boolean values" do
    expect { described_class.call(hide_nil: true) }.not_to raise_error
    expect { described_class.call(hide_nil: false) }.to raise_error Serega::Error, error(false)
    expect { described_class.call(hide_nil: "true") }.to raise_error Serega::Error, error("true")
    expect { described_class.call(hide_nil: nil) }.to raise_error Serega::Error, error(nil)
    expect { described_class.call(hide_nil: 0) }.to raise_error Serega::Error, error(0)
  end
end
