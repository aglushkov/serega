# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::CheckInitiateParams do
  subject(:validate) { described_class.new(opts).validate }

  let(:serializer) do
    keys = initiate_keys
    Class.new(Serega) do
      config[:initiate_keys] = keys
    end
  end
  let(:initiate_keys) { %i[opt1 opt2] }
  let(:opts) { {only: :foo, except: :bar, with: :bazz} }
  let(:described_class) { serializer::CheckInitiateParams }
  let(:check_modifiers_class) { Serega::SeregaValidations::Initiate::CheckModifiers }

  before do
    allow(Serega::SeregaValidations::Utils::CheckAllowedKeys).to receive(:call)
    allow(check_modifiers_class).to receive(:call)
  end

  it "checks valid keys" do
    validate
    expect(Serega::SeregaValidations::Utils::CheckAllowedKeys).to have_received(:call).with(opts, initiate_keys)
  end

  it "checks provided :only, :except, :with modifiers" do
    validate

    expect(check_modifiers_class).to have_received(:call).once.ordered.with(serializer, :foo)
    expect(check_modifiers_class).to have_received(:call).once.ordered.with(serializer, :bar)
    expect(check_modifiers_class).to have_received(:call).once.ordered.with(serializer, :bazz)
  end
end