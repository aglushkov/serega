# frozen_string_literal: true

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch::CheckOptBatch do
  subject(:check) { described_class.call(opts, block, ser) }

  let(:ser) { Class.new(Serega) { plugin :batch } }
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
    opts[:batch] = {key: nil, loader: nil, default: nil, foo: nil}
    expect { check }.to raise_error Serega::SeregaError, /foo/
  end

  it "checks sub option :key is present" do
    opts[:batch] = {loader: :abc}
    expect { check }.to raise_error Serega::SeregaError, "Option :key must present inside :batch option"
  end

  it "allows to skip sub option :key if default key specified" do
    ser.config.batch.default_key = :id
    opts[:batch] = {loader: :abc}
    expect { check }.not_to raise_error
  end

  it "checks sub option :loader is present" do
    opts[:batch] = {key: :abc}
    expect { check }.to raise_error Serega::SeregaError, "Option :loader must present inside :batch option"
  end

  it "checks sub options :key and :loader" do
    opts[:batch] = {key: :key_name, loader: :loader_name}
    allow(Serega::SeregaPlugins::Batch::CheckBatchOptLoader).to receive(:call).with(:loader_name)
    allow(Serega::SeregaPlugins::Batch::CheckBatchOptKey).to receive(:call).with(:key_name)

    check

    expect(Serega::SeregaPlugins::Batch::CheckBatchOptLoader).to have_received(:call).with(:loader_name)
    expect(Serega::SeregaPlugins::Batch::CheckBatchOptKey).to have_received(:call).with(:key_name)
  end

  it "prohibits to use with :key opt" do
    opts.merge!(batch: {key: :key, loader: :loader}, key: :key)
    expect { check }
      .to raise_error Serega::SeregaError, "Option :batch can not be used together with option :key"
  end

  it "prohibits to use with :value opt" do
    opts.merge!(batch: {key: :key, loader: :loader}, value: -> {})
    expect { check }
      .to raise_error Serega::SeregaError, "Option :batch can not be used together with option :value"
  end

  it "prohibits to use with :const opt" do
    opts.merge!(batch: {key: :key, loader: :loader}, const: 1)
    expect { check }
      .to raise_error Serega::SeregaError, "Option :batch can not be used together with option :const"
  end

  it "prohibits to use with :delegate opt" do
    opts.merge!(batch: {key: :key, loader: :loader}, delegate: {to: :foo})
    expect { check }
      .to raise_error Serega::SeregaError, "Option :batch can not be used together with option :delegate"
  end

  it "prohibits to use with block" do
    opts[:batch] = {key: :key, loader: :loader}
    expect { described_class.call(opts, proc {}, ser) }
      .to raise_error Serega::SeregaError, "Option :batch can not be used together with block"
  end
end
