# frozen_string_literal: true

RSpec.describe Serega::SeregaValidations::Attribute::CheckOptLazy do
  subject(:check) { described_class.call(serializer, opts, block) }

  let(:serializer) { Class.new(Serega) }
  let(:opts) { {} }
  let(:block) { nil }

  before do
    serializer.lazy_loaders[:test_loader] = proc {}
  end

  it "allows no :lazy option" do
    opts[:foo] = nil
    expect { check }.not_to raise_error
  end

  it "allows :lazy option to be true" do
    opts[:lazy] = true
    expect { check }.not_to raise_error
  end

  it "allows :lazy option to be a proc" do
    opts[:lazy] = proc {}
    expect { check }.not_to raise_error
  end

  it "allows :lazy option to be a symbol of defined loader" do
    opts[:lazy] = :test_loader
    expect { check }.not_to raise_error
  end

  it "allows :lazy option to be a string of defined loader" do
    opts[:lazy] = "test_loader"
    expect { check }.not_to raise_error
  end

  it "raises error when lazy loader is not defined" do
    opts[:lazy] = :undefined_loader
    expect { check }.to raise_error Serega::SeregaError, "Lazy loader with name `:undefined_loader` is not defined"
  end

  context "when :lazy is a hash" do
    it "checks allowed keys" do
      opts[:lazy] = {use: :test_loader, id: :id, foo: nil}
      expect { check }.to raise_error Serega::SeregaError, /foo/
    end

    it "allows :use option with defined loader" do
      opts[:lazy] = {use: :test_loader}
      expect { check }.not_to raise_error
    end

    it "allows :use option with proc" do
      opts[:lazy] = {use: proc {}}
      expect { check }.not_to raise_error
    end

    it "raises error when :use loader is not defined" do
      opts[:lazy] = {use: :undefined_loader}
      expect { check }.to raise_error Serega::SeregaError, "Lazy loader with name `:undefined_loader` is not defined"
    end

    it "allows :id option with symbol" do
      opts[:lazy] = {use: :test_loader, id: :id}
      expect { check }.not_to raise_error
    end

    it "allows :id option with string" do
      opts[:lazy] = {use: :test_loader, id: "id"}
      expect { check }.not_to raise_error
    end

    it "raises error when :id is not a symbol or string" do
      opts[:lazy] = {use: :test_loader, id: 123}
      expect { check }.to raise_error Serega::SeregaError, "Invalid lazy option `:id` value, it can be a Symbol or a String"
    end
  end

  context "with multiple loaders" do
    before do
      serializer.lazy_loaders[:loader1] = proc {}
      serializer.lazy_loaders[:loader2] = proc {}
    end

    it "allows multiple loaders with :value option" do
      opts[:lazy] = {use: [:loader1, :loader2]}
      opts[:value] = proc {}
      expect { check }.not_to raise_error
    end

    it "allows multiple loaders with block" do
      opts[:lazy] = {use: [:loader1, :loader2]}
      expect { described_class.call(serializer, opts, proc {}) }.not_to raise_error
    end

    it "raises error when multiple loaders without :value or block" do
      opts[:lazy] = {use: [:loader1, :loader2]}
      expect { check }.to raise_error Serega::SeregaError, "Attribute :value option or block should be provided when selecting multiple lazy loaders"
    end

    it "raises error when multiple loaders with :id option" do
      opts[:lazy] = {use: [:loader1, :loader2], id: :id}
      expect { check }.to raise_error Serega::SeregaError, "Option `lazy.id` should not be used with multiple loaders provided in `lazy.use`"
    end
  end

  context "with other options" do
    it "prohibits to use with :method opt" do
      opts.merge!(lazy: :test_loader, method: :method)
      expect { check }.to raise_error Serega::SeregaError, "Option :lazy can not be used together with option :method"
    end

    it "prohibits to use with :const opt" do
      opts.merge!(lazy: :test_loader, const: 1)
      expect { check }.to raise_error Serega::SeregaError, "Option :lazy can not be used together with option :const"
    end

    it "prohibits to use with :delegate opt" do
      opts.merge!(lazy: :test_loader, delegate: {to: :foo})
      expect { check }.to raise_error Serega::SeregaError, "Option :lazy can not be used together with option :delegate"
    end

    it "prohibits to use :id with :value option" do
      opts.merge!(lazy: {use: :test_loader, id: :id}, value: proc {})
      expect { check }.to raise_error Serega::SeregaError, "Option `lazy.id` should not be used when :value or block provided directly"
    end
  end
end
