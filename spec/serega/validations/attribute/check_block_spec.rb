# frozen_string_literal: true

RSpec.describe Serega::Attribute::CheckBlock do
  let(:block_error) { "Block can have maximum two regular parameters (no **keyword or *array args)" }
  let(:value_error) { "Option :value must be a Proc that is able to accept two parameters (no **keyword or *array args)" }
  let(:both_error) { "Block and a :value option can not be provided together" }
  let(:opts) { {} }
  let(:block) { nil }

  it "allows no block" do
    expect { described_class.call(opts, nil) }.not_to raise_error
  end

  it "prohibits value option and a block together" do
    opts = {value: nil}
    block = proc {}
    expect { described_class.call(opts, block) }.to raise_error Serega::Error, both_error
  end

  it "allows block with no params" do
    block = proc {}
    expect { described_class.call(opts, block) }.not_to raise_error
  end

  it "allows value with no params" do
    opts[:value] = proc {}
    expect { described_class.call(opts, block) }.not_to raise_error
  end

  it "prohibits value defined as lambda without params" do
    opts[:value] = -> {}
    expect { described_class.call(opts, block) }.to raise_error Serega::Error, value_error
  end

  it "allows block with one parameter" do
    block = proc { |_obj| }
    expect { described_class.call(opts, block) }.not_to raise_error
  end

  it "allows value with one parameter" do
    opts[:value] = proc { |_obj| }
    expect { described_class.call(opts, block) }.not_to raise_error
  end

  it "prohibits lambda value with one parameter" do
    opts[:value] = ->(_obj) {}
    expect { described_class.call(opts, block) }.to raise_error Serega::Error, value_error
  end

  it "allows block with two parameters" do
    block = proc { |_obj, _ctx| }
    expect { described_class.call(opts, block) }.not_to raise_error
  end

  it "allows value with two parameters" do
    opts[:value] = proc { |_obj, _ctx| }
    expect { described_class.call(opts, block) }.not_to raise_error
  end

  it "allows lambda value with two parameters" do
    opts[:value] = ->(_obj, _ctx) {}
    expect { described_class.call(opts, block) }.not_to raise_error
  end

  it "prohibits block with three parameters" do
    block = proc { |_obj, _ctx, _foo| }
    expect { described_class.call(opts, block) }.to raise_error Serega::Error, block_error
  end

  it "prohibits value with three parameters" do
    opts[:value] = proc { |_obj, _ctx, _foo| }
    expect { described_class.call(opts, block) }.to raise_error Serega::Error, value_error
  end

  it "prohibits lambda value with three parameters" do
    opts[:value] = ->(_obj, _ctx, _foo) {}
    expect { described_class.call(opts, block) }.to raise_error Serega::Error, value_error
  end

  it "prohibits *rest parameters" do
    block = proc { |*_foo| }
    expect { described_class.call(opts, block) }.to raise_error Serega::Error, block_error
  end

  it "prohibits lambda with *rest parameters" do
    opts[:value] = ->(_obj, *_ctx) {}
    expect { described_class.call(opts, block) }.to raise_error Serega::Error, value_error
  end

  it "prohibits **keywords parameters" do
    block = proc { |**_foo| }
    expect { described_class.call(opts, block) }.to raise_error Serega::Error, block_error
  end

  it "prohibits lambda with *keywords parameters" do
    opts[:value] = ->(_obj, **_ctx) {}
    expect { described_class.call(opts, block) }.to raise_error Serega::Error, value_error
  end
end
