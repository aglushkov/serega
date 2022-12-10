# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::CheckInitiateParams do
  subject(:validate) { described_class.new(opts).validate }

  let(:serializer) { Class.new(Serega) }
  let(:opts) { {only: {foo: {}}, except: {bar: {}}, with: {bazz: {}}} }
  let(:described_class) { serializer::CheckInitiateParams }
  let(:check_modifiers) { Serega::SeregaValidations::Initiate::CheckModifiers.new }

  before do
    allow(Serega::SeregaValidations::Utils::CheckAllowedKeys).to receive(:call)
    allow(Serega::SeregaValidations::Initiate::CheckModifiers).to receive(:new).and_return(check_modifiers)
    allow(check_modifiers).to receive(:call)
  end

  it "checks valid keys and modifiers fields" do
    validate

    expect(Serega::SeregaValidations::Utils::CheckAllowedKeys)
      .to have_received(:call).with(opts, serializer.config.initiate_keys)

    expect(check_modifiers).to have_received(:call).with(serializer, {foo: {}}, {bazz: {}}, {bar: {}})
  end
end
