# frozen_string_literal: true

load_plugin_code(:metadata)

RSpec.describe Serega::Plugins::Metadata::MetaAttribute::CheckOptHideEmpty do
  def error(value)
    "Invalid option :hide_empty => #{value.inspect}. Must be true"
  end

  it "allows only boolean values" do
    expect { described_class.call(hide_empty: true) }.not_to raise_error
    expect { described_class.call(hide_empty: false) }.to raise_error Serega::Error, error(false)
    expect { described_class.call(hide_empty: "true") }.to raise_error Serega::Error, error("true")
    expect { described_class.call(hide_empty: nil) }.to raise_error Serega::Error, error(nil)
    expect { described_class.call(hide_empty: 0) }.to raise_error Serega::Error, error(0)
  end
end
