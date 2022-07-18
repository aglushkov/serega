# frozen_string_literal: true

RSpec.describe Serega::Validations::CheckAttributeParams do
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
    allow(Serega::Validations::Utils::CheckAllowedKeys).to receive(:call)
    allow(Serega::Validations::Attribute::CheckBlock).to receive(:call)
    allow(Serega::Validations::Attribute::CheckName).to receive(:call)
    allow(Serega::Validations::Attribute::CheckOptConst).to receive(:call)
    allow(Serega::Validations::Attribute::CheckOptHide).to receive(:call)
    allow(Serega::Validations::Attribute::CheckOptKey).to receive(:call)
    allow(Serega::Validations::Attribute::CheckOptMany).to receive(:call)
    allow(Serega::Validations::Attribute::CheckOptSerializer).to receive(:call)
    allow(Serega::Validations::Attribute::CheckOptValue).to receive(:call)
  end

  it "checks valid keys" do
    validate
    expect(Serega::Validations::Utils::CheckAllowedKeys).to have_received(:call).with(opts, attribute_keys)
  end

  it "checks each option value" do
    validate

    expect(Serega::Validations::Attribute::CheckBlock).to have_received(:call).with(block)
    expect(Serega::Validations::Attribute::CheckName).to have_received(:call).with(name)
    expect(Serega::Validations::Attribute::CheckOptConst).to have_received(:call).with(opts, block)
    expect(Serega::Validations::Attribute::CheckOptHide).to have_received(:call).with(opts)
    expect(Serega::Validations::Attribute::CheckOptKey).to have_received(:call).with(opts, block)
    expect(Serega::Validations::Attribute::CheckOptMany).to have_received(:call).with(opts)
    expect(Serega::Validations::Attribute::CheckOptSerializer).to have_received(:call).with(opts)
    expect(Serega::Validations::Attribute::CheckOptValue).to have_received(:call).with(opts, block)
  end
end
