# frozen_string_literal: true

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch::CheckBatchOptLoader do
  let(:serializer) { Class.new(Serega) { plugin :batch } }

  let(:params_count_error) do
    "Invalid :batch option :loader. It can accept maximum 3 parameters (ids, context, plan)"
  end

  let(:must_be_callable) do
    "Invalid :batch option :loader. It must be a Symbol, a Proc or respond to :call"
  end

  it "prohibits non-proc, non-callable values" do
    expect { described_class.call(nil, serializer) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call("String", serializer) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call([], serializer) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call({}, serializer) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(Object, serializer) }.to raise_error Serega::SeregaError, must_be_callable
    expect { described_class.call(Object.new, serializer) }.to raise_error Serega::SeregaError, must_be_callable
  end

  it "allows loaders with maximum 3 args" do
    expect { described_class.call(lambda {}, serializer) }.not_to raise_error
    expect { described_class.call(lambda { |ids| }, serializer) }.not_to raise_error
    expect { described_class.call(lambda { |ids, ctx| }, serializer) }.not_to raise_error
    expect { described_class.call(lambda { |ids, ctx, plan| }, serializer) }.not_to raise_error
    expect { described_class.call(lambda { |a, b, c, d| }, serializer) }.to raise_error Serega::SeregaError, params_count_error
  end

  context "when Symbol provided as loader_name" do
    it "raises error if loader was not defined" do
      expect { described_class.call(:foo, serializer) }
        .to raise_error Serega::SeregaError,
          "Please define loader before adding it to attribute.\n  Example: `config.batch.define(:foo) { |ids| ... }`"
    end

    it "does not raise error when loader was not defined earlier" do
      serializer.config.batch.define(:foo, proc {})
      expect { described_class.call(:foo, serializer) }.not_to raise_error
    end
  end
end
