# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Utils::CheckAllowedKeys do
  let(:opts) { {opt1: :foo, opt2: :bar} }
  let(:attribute_keys) { %i[opt1 opt2] }

  it "checks valid keys" do
    expect { described_class.call(opts, attribute_keys, :param) }.not_to raise_error

    expect { described_class.call(opts, %i[opt1 opt5 opt4], :PARAM_NAME) }
      .to raise_error Serega::SeregaError,
        "Invalid PARAM_NAME option :opt2. Allowed options are: :opt1, :opt4, :opt5"
  end
end
