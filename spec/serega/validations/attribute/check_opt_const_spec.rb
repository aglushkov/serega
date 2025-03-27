# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckOptConst do
  subject(:check) { described_class.call(opts, block) }

  let(:opts) { {} }
  let(:block) { nil }

  it "allows no :const option" do
    opts[:foo] = nil
    expect { check }.not_to raise_error
  end

  it "allows :const option with any value" do
    opts[:const] = 1
    expect { check }.not_to raise_error
  end

  it "allows :const option with nil value" do
    opts[:const] = nil
    expect { check }.not_to raise_error
  end

  it "allows :const option with string value" do
    opts[:const] = "test"
    expect { check }.not_to raise_error
  end

  it "allows :const option with symbol value" do
    opts[:const] = :test
    expect { check }.not_to raise_error
  end

  context "with other options" do
    it "prohibits to use with :method opt" do
      opts.merge!(const: 1, method: :method)
      expect { check }.to raise_error Serega::SeregaError, "Option :const can not be used together with option :method"
    end

    it "prohibits to use with :value opt" do
      opts.merge!(const: 1, value: proc {})
      expect { check }.to raise_error Serega::SeregaError, "Option :const can not be used together with option :value"
    end

    it "prohibits to use with :lazy opt" do
      opts.merge!(const: 1, lazy: :test_loader)
      expect { check }.to raise_error Serega::SeregaError, "Option :const can not be used together with option :lazy"
    end

    it "prohibits to use with block" do
      opts[:const] = 1
      expect { described_class.call(opts, proc {}) }.to raise_error Serega::SeregaError, "Option :const can not be used together with block"
    end
  end
end
