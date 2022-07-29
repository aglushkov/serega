# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckBlock do
  let(:block_error) { "Block can have maximum two regular parameters (no **keyword or *array args)" }
  let(:block) { nil }

  it "allows no block" do
    expect { described_class.call(nil) }.not_to raise_error
  end

  it "allows block with no params" do
    block = proc {}
    expect { described_class.call(block) }.not_to raise_error
  end

  it "allows block with one parameter" do
    block = proc { |_obj| }
    expect { described_class.call(block) }.not_to raise_error
  end

  it "allows block with two parameters" do
    block = proc { |_obj, _ctx| }
    expect { described_class.call(block) }.not_to raise_error
  end

  it "prohibits block with three parameters" do
    block = proc { |_obj, _ctx, _foo| }
    expect { described_class.call(block) }.to raise_error Serega::Error, block_error
  end

  it "prohibits *rest parameters" do
    block = proc { |*_foo| }
    expect { described_class.call(block) }.to raise_error Serega::Error, block_error
  end

  it "prohibits **keywords parameters" do
    block = proc { |**_foo| }
    expect { described_class.call(block) }.to raise_error Serega::Error, block_error
  end
end
