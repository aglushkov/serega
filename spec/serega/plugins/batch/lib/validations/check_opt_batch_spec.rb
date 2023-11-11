# frozen_string_literal: true

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch::CheckOptBatch do
  subject(:check) { described_class.call(opts, block, serializer) }

  let(:serializer) { Class.new(Serega) { plugin :batch } }
  let(:opts) { {} }
  let(:block) { nil }

  it "allows no :batch option" do
    opts[:foo] = nil
    expect { check }.not_to raise_error
  end

  it "checks :batch option is a Hash" do
    opts[:batch] = proc {}
    expect { check }.to raise_error Serega::SeregaError, /Must have a Hash value/
  end

  it "checks allowed keys" do
    opts[:batch] = {id_method: nil, loader: nil, default: nil, foo: nil}
    expect { check }.to raise_error Serega::SeregaError, /foo/
  end

  it "checks sub option :id_method is present" do
    opts[:batch] = {loader: proc {}}
    expect { check }.to raise_error Serega::SeregaError, "Option :id_method must present inside :batch option"
  end

  it "allows to skip sub option :id_method if default is specified" do
    serializer.config.batch.id_method = :id
    opts[:batch] = {loader: proc {}}
    expect { check }.not_to raise_error
  end

  it "checks sub option :loader is present" do
    opts[:batch] = {id_method: :abc}
    expect { check }.to raise_error Serega::SeregaError, "Option :loader must present inside :batch option"
  end

  it "checks sub options :id and :loader" do
    opts[:batch] = {id_method: :id_name, loader: :loader_name}
    allow(Serega::SeregaPlugins::Batch::CheckBatchOptLoader).to receive(:call)
    allow(Serega::SeregaPlugins::Batch::CheckBatchOptIdMethod).to receive(:call)

    check

    expect(Serega::SeregaPlugins::Batch::CheckBatchOptLoader).to have_received(:call).with(:loader_name, serializer)
    expect(Serega::SeregaPlugins::Batch::CheckBatchOptIdMethod).to have_received(:call).with(:id_name)
  end

  it "prohibits to use with :method opt" do
    opts.merge!(batch: {id_method: :id, loader: proc {}}, method: :method)
    expect { check }
      .to raise_error Serega::SeregaError, "Option :batch can not be used together with option :method"
  end

  it "prohibits to use with :value opt" do
    opts.merge!(batch: {id_method: :id, loader: proc {}}, value: -> {})
    expect { check }
      .to raise_error Serega::SeregaError, "Option :batch can not be used together with option :value"
  end

  it "prohibits to use with :const opt" do
    opts.merge!(batch: {id_method: :id, loader: proc {}}, const: 1)
    expect { check }
      .to raise_error Serega::SeregaError, "Option :batch can not be used together with option :const"
  end

  it "prohibits to use with :delegate opt" do
    opts.merge!(batch: {id_method: :id, loader: proc {}}, delegate: {to: :foo})
    expect { check }
      .to raise_error Serega::SeregaError, "Option :batch can not be used together with option :delegate"
  end

  it "prohibits to use with block" do
    opts[:batch] = {id_method: :id, loader: proc {}}
    expect { described_class.call(opts, proc {}, serializer) }
      .to raise_error Serega::SeregaError, "Option :batch can not be used together with block"
  end
end
