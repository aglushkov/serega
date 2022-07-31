# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::SeregaPlugins::Preloads::CheckOptPreload do
  it "prohibits to use with :const opt" do
    expect { described_class.call(preload: :foo, const: 1) }
      .to raise_error Serega::SeregaError, "Option :preload can not be used together with option :const"
  end
end
