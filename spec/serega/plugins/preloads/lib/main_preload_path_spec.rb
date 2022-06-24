# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::Plugins::Preloads::MainPreloadPath do
  let(:main_path) { described_class }

  it "returns empty array when preloads are empty" do
    expect(main_path.call({})).to eq []
  end

  it "returns path to last preloaded element" do
    expect(main_path.call(foo: {})).to eq %i[foo]
    expect(main_path.call(foo: {bar: {}})).to eq %i[foo bar]
    expect(main_path.call(foo: {bar1: {}, bar2: {}})).to eq %i[foo bar2]
    expect(main_path.call(foo: {bar: {}}, bazz: {})).to eq %i[bazz]
  end
end
