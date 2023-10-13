# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckOptDelegate do
  it "allows valid value" do
    expect { described_class.call(delegate: {to: :foo}) }.not_to raise_error
    expect { described_class.call(delegate: {to: :foo, allow_nil: true}) }.not_to raise_error
    expect { described_class.call(delegate: {to: :foo, allow_nil: false}) }.not_to raise_error
  end

  it "checks delegate option is a hash" do
    expect { described_class.call(delegate: :foo) }
      .to raise_error Serega::SeregaError, "Invalid option :delegate => :foo. Must have a Hash value"
  end

  it "checks delegate option :to value present" do
    expect { described_class.call(delegate: {}) }
      .to raise_error Serega::SeregaError, "Option :delegate must have a :to option"
  end

  it "checks option :to is a Symbol or String" do
    expect { described_class.call(delegate: {to: 123}) }
      .to raise_error Serega::SeregaError, "Invalid option :to => 123. Must be a String or a Symbol"
  end

  it "checks option :allow_nil has a boolean value" do
    expect { described_class.call(delegate: {to: :foo, allow_nil: 1}) }
      .to raise_error Serega::SeregaError, "Invalid option :allow_nil => 1. Must have a boolean value"
  end

  it "checks option :method is a String or a Symbol" do
    expect { described_class.call(delegate: {to: :foo, method: 123}) }
      .to raise_error Serega::SeregaError, "Invalid option :method => 123. Must be a String or a Symbol"
  end

  it "checks has no extra options" do
    allow(Serega::SeregaValidations::Utils::CheckAllowedKeys).to receive(:call)

    described_class.call(delegate: {to: :foo})
    expect(Serega::SeregaValidations::Utils::CheckAllowedKeys)
      .to have_received(:call)
      .with({to: :foo}, %i[to method allow_nil], :delegate)
  end

  it "prohibits to use with :method opt" do
    expect { described_class.call(delegate: {to: :foo}, method: :bar) }
      .to raise_error Serega::SeregaError, "Option :delegate can not be used together with option :method"
  end

  it "prohibits to use with :const opt" do
    expect { described_class.call(delegate: {to: :foo}, const: 123) }
      .to raise_error Serega::SeregaError, "Option :delegate can not be used together with option :const"
  end

  it "prohibits to use with :value opt" do
    expect { described_class.call(delegate: {to: :foo}, value: -> {}) }
      .to raise_error Serega::SeregaError, "Option :delegate can not be used together with option :value"
  end

  it "prohibits to use with block" do
    expect { described_class.call({delegate: {to: :foo}}, proc {}) }
      .to raise_error Serega::SeregaError, "Option :delegate can not be used together with block"
  end
end
