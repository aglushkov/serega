# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckOptValue do
  let(:value_error) { "Option :value must be a Proc that is able to accept two parameters (no **keyword or *array args)" }
  let(:opts) { {} }

  it "prohibits to use with :key opt" do
    expect { described_class.call({value: proc {}, key: :foo}) }
      .to raise_error Serega::SeregaError, "Option :value can not be used together with option :key"
  end

  it "prohibits to use with :const opt" do
    expect { described_class.call(value: proc {}, const: 1) }
      .to raise_error Serega::SeregaError, "Option :value can not be used together with option :const"
  end

  it "prohibits to use with block" do
    expect { described_class.call({value: proc {}}, proc {}) }
      .to raise_error Serega::SeregaError, "Option :value can not be used together with block"
  end

  it "allows value with no params" do
    opts[:value] = proc {}
    expect { described_class.call(opts) }.not_to raise_error
  end

  it "prohibits value defined as lambda without params" do
    opts[:value] = -> {}
    expect { described_class.call(opts) }.to raise_error Serega::SeregaError, value_error
  end

  it "allows value with one parameter" do
    opts[:value] = proc { |_obj| }
    expect { described_class.call(opts) }.not_to raise_error
  end

  it "prohibits lambda value with one parameter" do
    opts[:value] = ->(_obj) {}
    expect { described_class.call(opts) }.to raise_error Serega::SeregaError, value_error
  end

  it "allows value with two parameters" do
    opts[:value] = proc { |_obj, _ctx| }
    expect { described_class.call(opts) }.not_to raise_error
  end

  it "allows lambda value with two parameters" do
    opts[:value] = ->(_obj, _ctx) {}
    expect { described_class.call(opts) }.not_to raise_error
  end

  it "prohibits value with three parameters" do
    opts[:value] = proc { |_obj, _ctx, _foo| }
    expect { described_class.call(opts) }.to raise_error Serega::SeregaError, value_error
  end

  it "prohibits lambda value with three parameters" do
    opts[:value] = ->(_obj, _ctx, _foo) {}
    expect { described_class.call(opts) }.to raise_error Serega::SeregaError, value_error
  end

  it "prohibits lambda with *rest parameters" do
    opts[:value] = ->(_obj, *_ctx) {}
    expect { described_class.call(opts) }.to raise_error Serega::SeregaError, value_error
  end

  it "prohibits lambda with *keywords parameters" do
    opts[:value] = ->(_obj, **_ctx) {}
    expect { described_class.call(opts) }.to raise_error Serega::SeregaError, value_error
  end
end
