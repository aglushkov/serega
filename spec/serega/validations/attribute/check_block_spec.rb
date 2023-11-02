# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckBlock do
  let(:params_count_error) { "Block can have maximum two parameters (object, context)" }
  let(:keyword_error) { "Invalid block. It should not have any required keyword arguments" }
  let(:block) { nil }

  it "allows no block" do
    expect { described_class.call(nil) }.not_to raise_error
  end

  it "checks extra keyword arguments" do
    expect { described_class.call(proc { |a:| }) }.to raise_error Serega::SeregaError, keyword_error
  end

  it "checks block has maximum 2 args" do
    block = proc {}
    counter = Serega::SeregaUtils::ParamsCount
    allow(counter).to receive(:call).and_return(0, 1, 2, 3)

    expect { described_class.call(block) }.not_to raise_error
    expect { described_class.call(block) }.not_to raise_error
    expect { described_class.call(block) }.not_to raise_error
    expect { described_class.call(block) }.to raise_error Serega::SeregaError, params_count_error

    expect(counter).to have_received(:call).with(block, max_count: 2).exactly(4).times
  end
end
