# frozen_string_literal: true

# Serega::SeregaPlugins.find_plugin(:metadata)
load_plugin_code(:metadata)

RSpec.describe Serega::SeregaPlugins::Metadata::MetaAttribute::CheckBlock do
  let(:error) { "Block can have maximum 2 regular parameters (no **keyword or *array args)" }

  it "allows no params" do
    block = proc {}
    expect { described_class.call(block) }.not_to raise_error

    block = lambda {}
    expect { described_class.call(block) }.not_to raise_error
  end

  it "allows one parameter" do
    block = proc { |_obj| } # optional parameter
    expect { described_class.call(block) }.not_to raise_error

    block = ->(_obj) {} # required parameter
    expect { described_class.call(block) }.not_to raise_error
  end

  it "allows two parameters" do
    block = proc { |_obj, _ctx| } # optional parameters
    expect { described_class.call(block) }.not_to raise_error

    block = ->(_obj, _ctx) {} # required parameters
    expect { described_class.call(block) }.not_to raise_error
  end

  it "prohibits three parameters" do
    block = proc { |_obj, _ctx, _foo| }
    expect { described_class.call(block) }.to raise_error Serega::Error, error
  end

  it "prohibits *rest parameters" do
    block = proc { |*_foo| }
    expect { described_class.call(block) }.to raise_error Serega::Error, error
  end

  it "prohibits **keywords parameters" do
    block = proc { |**_foo| }
    expect { described_class.call(block) }.to raise_error Serega::Error, error
  end
end
