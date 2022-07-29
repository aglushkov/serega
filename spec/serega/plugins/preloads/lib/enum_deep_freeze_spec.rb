# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::SeregaPlugins::Preloads::EnumDeepFreeze do
  it "deeply freezes provided hash" do
    hash = {key1: {key11: {key111: :value111}}, key2: [{key22: {key222: :value222}}]}
    described_class.call(hash)

    expect(hash).to be_frozen
    expect(hash[:key1]).to be_frozen
    expect(hash[:key1][:key11]).to be_frozen

    expect(hash[:key2]).to be_frozen
    expect(hash[:key2][0]).to be_frozen
    expect(hash[:key2][0][:key22]).to be_frozen
  end
end
