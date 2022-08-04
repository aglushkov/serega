# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Utils::CheckAllowedKeys do
  let(:opts) { {opt1: :foo, opt2: :bar} }
  let(:attribute_keys) { %i[opt1 opt2] }

  def invalid_key_error(key, attribute_keys)
    "Invalid option #{key.inspect}. Allowed options are: #{attribute_keys.map(&:inspect).join(", ")}"
  end

  it "checks valid keys" do
    expect { described_class.call(opts, attribute_keys) }.not_to raise_error

    expect { described_class.call(opts, %i[opt1]) }
      .to raise_error Serega::SeregaError, invalid_key_error(:opt2, %i[opt1])
  end
end
