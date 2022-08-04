# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::CheckSerializeParams do
  subject(:validate) { described_class.new(opts).validate }

  let(:serializer) do
    keys = serialize_keys
    Class.new(Serega) do
      config[:serialize_keys] = keys
    end
  end
  let(:serialize_keys) { %i[opt1 opt2] }
  let(:opts) { {only: :foo, except: :bar, with: :bazz} }
  let(:described_class) { serializer::CheckSerializeParams }

  before do
    allow(Serega::SeregaValidations::Utils::CheckAllowedKeys).to receive(:call)
    allow(Serega::SeregaValidations::Utils::CheckOptIsHash).to receive(:call)
    allow(Serega::SeregaValidations::Utils::CheckOptIsBool).to receive(:call)
  end

  it "checks valid keys" do
    validate
    expect(Serega::SeregaValidations::Utils::CheckAllowedKeys).to have_received(:call).with(opts, serialize_keys)
    expect(Serega::SeregaValidations::Utils::CheckOptIsHash).to have_received(:call).with(opts, :context)
    expect(Serega::SeregaValidations::Utils::CheckOptIsBool).to have_received(:call).with(opts, :many)
  end
end
