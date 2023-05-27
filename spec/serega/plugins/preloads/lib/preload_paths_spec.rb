# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::SeregaPlugins::Preloads::PreloadPaths do
  let(:paths) { described_class }

  it "generates empty paths array for blank input" do
    expect(paths.call(nil)).to eq []
    expect(paths.call([])).to eq []
    expect(paths.call({})).to eq []
    expect(paths.call(false)).to eq []
  end

  it "generates paths for single element" do
    expect(paths.call(:foo)).to eq [[:foo]]
    expect(paths.call("foo")).to eq [[:foo]]
  end

  it "generates paths for array" do
    expect(paths.call([:foo, :bar])).to eq [[:foo], [:bar]]
  end

  it "generates paths for hash" do
    expect(paths.call(foo: :bar)).to eq [[:foo], [:foo, :bar]]
  end

  it "generates paths for hash of hash" do
    expect(paths.call(foo: {bar: :bazz})).to eq [
      [:foo],
      [:foo, :bar],
      [:foo, :bar, :bazz]
    ]
  end

  it "generates paths for hash of array" do
    expect(paths.call(foo: [:bar, :bazz])).to eq [
      [:foo],
      [:foo, :bar],
      [:foo, :bazz]
    ]
  end

  it "generates paths for array of hashes" do
    expect(paths.call([{foo: :bar}, {foo1: :bar1}])).to eq [
      [:foo],
      [:foo, :bar],
      [:foo1],
      [:foo1, :bar1]
    ]

    puts paths.call({a: {b: {c: {}, d: {}}}, e: {}}).inspect
  end

  it "generates paths for deeply nested hash" do
    expect(paths.call({a: {b: {c: {}, d: {}}}, e: {}})).to eq [
      [:a],
      [:a, :b],
      [:a, :b, :c],
      [:a, :b, :d],
      [:e]
    ]
  end
end
