# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::Plugins::Preloads::FormatUserPreloads do
  let(:format) { described_class }

  it "transforms nil to empty hash" do
    preloads = nil
    expect(format.call(preloads)).to eq({})
  end

  it "transforms false to empty hash" do
    preloads = false
    expect(format.call(preloads)).to eq({})
  end

  it "transforms Symbol" do
    preloads = :foo
    expect(format.call(preloads)).to eq({foo: {}})
  end

  it "transforms String" do
    preloads = "foo"
    expect(format.call(preloads)).to eq({foo: {}})
  end

  it "transforms Hash" do
    preloads = {foo: :bar}
    expect(format.call(preloads)).to eq({foo: {bar: {}}})
  end

  it "transforms Array" do
    preloads = %i[foo bar]
    expect(format.call(preloads)).to eq({foo: {}, bar: {}})
  end

  it "transforms nested hashes and arrays" do
    preloads = [:foo, {"bar" => "bazz"}, ["bazz"]]
    expect(format.call(preloads)).to eq({foo: {}, bar: {bazz: {}}, bazz: {}})

    preloads = {"bar" => "bazz", :foo => [:bar, "bazz"]}
    expect(format.call(preloads)).to eq({bar: {bazz: {}}, foo: {bar: {}, bazz: {}}})
  end
end
