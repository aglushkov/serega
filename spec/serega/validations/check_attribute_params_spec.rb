# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::CheckAttributeParams do
  subject(:validate) { described_class.new(*params).validate }

  let(:serializer) do
    keys = attribute_keys
    Class.new(Serega) do
      config[:attribute_keys] = keys
    end
  end
  let(:name) { :name }
  let(:opts) { {opt1: :foo, opt2: :bar} }
  let(:block) { proc {} }
  let(:params) { [name, opts, block] }
  let(:attribute_keys) { %i[opt1 opt2] }

  let(:described_class) { serializer::CheckAttributeParams }

  before do
    allow(Serega::SeregaValidations::SeregaUtils::CheckAllowedKeys).to receive(:call)
    allow(Serega::SeregaValidations::Attribute::CheckBlock).to receive(:call)
    allow(Serega::SeregaValidations::Attribute::CheckName).to receive(:call)
    allow(Serega::SeregaValidations::Attribute::CheckOptConst).to receive(:call)
    allow(Serega::SeregaValidations::Attribute::CheckOptHide).to receive(:call)
    allow(Serega::SeregaValidations::Attribute::CheckOptKey).to receive(:call)
    allow(Serega::SeregaValidations::Attribute::CheckOptMany).to receive(:call)
    allow(Serega::SeregaValidations::Attribute::CheckOptSerializer).to receive(:call)
    allow(Serega::SeregaValidations::Attribute::CheckOptValue).to receive(:call)
  end

  it "checks valid keys" do
    validate
    expect(Serega::SeregaValidations::SeregaUtils::CheckAllowedKeys).to have_received(:call).with(opts, attribute_keys)
  end

  it "checks each option value" do
    validate

    expect(Serega::SeregaValidations::Attribute::CheckBlock).to have_received(:call).with(block)
    expect(Serega::SeregaValidations::Attribute::CheckName).to have_received(:call).with(name)
    expect(Serega::SeregaValidations::Attribute::CheckOptConst).to have_received(:call).with(opts, block)
    expect(Serega::SeregaValidations::Attribute::CheckOptHide).to have_received(:call).with(opts)
    expect(Serega::SeregaValidations::Attribute::CheckOptKey).to have_received(:call).with(opts, block)
    expect(Serega::SeregaValidations::Attribute::CheckOptMany).to have_received(:call).with(opts)
    expect(Serega::SeregaValidations::Attribute::CheckOptSerializer).to have_received(:call).with(opts)
    expect(Serega::SeregaValidations::Attribute::CheckOptValue).to have_received(:call).with(opts, block)
  end
end
