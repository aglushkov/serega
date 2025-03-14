# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckBlock do
  let(:block) { nil }
  let(:signature_error) do
    <<~ERR.strip
      Invalid attribute block parameters, valid parameters signatures:
      - ()                # no parameters
      - (object)          # one positional parameter
      - (object, context) # two positional parameters
      - (object, :ctx)    # one positional parameter and :ctx keyword
    ERR
  end

  it "allows no block" do
    expect { described_class.call(nil) }.not_to raise_error
  end

  it "checks value parameters signature" do
    expect { described_class.call(lambda {}) }.not_to raise_error
    expect { described_class.call(lambda { |obj| }) }.not_to raise_error
    expect { described_class.call(lambda { |obj, ctx| }) }.not_to raise_error
    expect { described_class.call(lambda { |obj, ctx:| }) }.not_to raise_error
    expect { described_class.call(lambda { |obj, ctx: {}| }) }.not_to raise_error
    expect { described_class.call(lambda { |obj, context, ctx:| }) }
      .to raise_error Serega::SeregaError, signature_error
  end
end
