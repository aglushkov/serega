# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckBlock do
  let(:block_error) { "Block must have one or two parameters (object, context)" }
  let(:keyword_error) { "Block must must not have keyword parameters" }
  let(:block) { nil }

  it "allows no block" do
    expect { described_class.call(nil) }.not_to raise_error
  end

  it "allows block as Proc (not lambda) with at least 1 parameter, except keyword params" do
    block = proc {}
    expect { described_class.call(block) }.to raise_error Serega::SeregaError, block_error

    block = proc { |_one| }
    expect { described_class.call(block) }.not_to raise_error

    block = proc { |_one, _two| }
    expect { described_class.call(block) }.not_to raise_error

    block = proc { |_one, *rest| }
    expect { described_class.call(block) }.not_to raise_error

    block = proc { |*rest| }
    expect { described_class.call(block) }.not_to raise_error

    block = proc { |_one, _two, _three| }
    expect { described_class.call(block) }.not_to raise_error

    block = proc { |_one, _two, a = 3, *b, d: 4, **e, &block| }
    expect { described_class.call(block) }.not_to raise_error

    block = proc { |_one, ctx:| }
    expect { described_class.call(block) }.to raise_error Serega::SeregaError, keyword_error
  end

  it "allows block as lambda with 1-2 parameters" do
    block = lambda {}
    expect { described_class.call(block) }.to raise_error Serega::SeregaError, block_error

    block = lambda { |_one| }
    expect { described_class.call(block) }.not_to raise_error

    block = lambda { |_one, _two| }
    expect { described_class.call(block) }.not_to raise_error

    block = lambda { |_one, _two, _three| }
    expect { described_class.call(block) }.to raise_error Serega::SeregaError, block_error

    block = lambda { |_one, _two, a = 3, *b, d: 4, **e, &block| }
    expect { described_class.call(block) }.not_to raise_error

    block = lambda { |_one, ctx:| }
    expect { described_class.call(block) }.to raise_error Serega::SeregaError, keyword_error
  end
end
