# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckOptValue do
  let(:opts) { {} }

  let(:type_error) { "Option :value value must be a Proc or respond to #call" }
  let(:signature_error) do
    <<~ERR.strip
      Invalid attribute :value option parameters, valid parameters signatures:
      - ()                # no parameters
      - (object)          # one positional parameter
      - (object, context) # two positional parameters
      - (object, :ctx)    # one positional parameter and :ctx keyword
    ERR
  end

  it "prohibits to use with :method opt" do
    expect { described_class.call({value: proc {}, method: :foo}) }
      .to raise_error Serega::SeregaError, "Option :value can not be used together with option :method"
  end

  it "prohibits to use with :const opt" do
    expect { described_class.call(value: proc {}, const: 1) }
      .to raise_error Serega::SeregaError, "Option :value can not be used together with option :const"
  end

  it "prohibits to use with block" do
    expect { described_class.call({value: proc {}}, proc {}) }
      .to raise_error Serega::SeregaError, "Option :value can not be used together with block"
  end

  it "checks value parameters signature" do
    expect { described_class.call(value: lambda {}) }.not_to raise_error
    expect { described_class.call(value: lambda { |obj| }) }.not_to raise_error
    expect { described_class.call(value: lambda { |obj, ctx| }) }.not_to raise_error
    expect { described_class.call(value: lambda { |obj, ctx:| }) }.not_to raise_error
    expect { described_class.call(value: lambda { |obj, ctx: {}| }) }.not_to raise_error
    expect { described_class.call(value: lambda { |obj, context, ctx:| }) }
      .to raise_error Serega::SeregaError, signature_error
  end

  it "checks keyword value" do
    expect { described_class.call({value: :value}) }
      .to raise_error Serega::SeregaError, type_error
  end
end
