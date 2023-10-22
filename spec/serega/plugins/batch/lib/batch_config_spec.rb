# frozen_string_literal: true

require "support/activerecord"

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch::BatchConfig do
  let(:batch_config) { described_class.new({loaders: {}}) }

  describe "#define" do
    it "defines named loader" do
      loader = proc { |a| }
      batch_config.define(:name, &loader)
      expect(batch_config.loaders).to eq(name: loader)
    end

    it "raises error when block not provided" do
      expect { batch_config.define(:name) }
        .to raise_error Serega::SeregaError, "Batch loader can be specified with one of arguments - callable value or &block"
    end

    it "raises error when provided incorrect params" do
      expect { batch_config.define(:name) {} }.to raise_error "Batch loader should have 1 to 3 parameters (keys, context, plan)"
      expect { batch_config.define(:name) { |a| } }.not_to raise_error
      expect { batch_config.define(:name) { |a, b| } }.not_to raise_error
      expect { batch_config.define(:name) { |a, b, c| } }.not_to raise_error
      expect { batch_config.define(:name) { |a, b, c, d| } }.not_to raise_error
      expect { batch_config.define(:name, &lambda { |a, b, c, d| }) }.to raise_error "Batch loader should have 1 to 3 parameters (keys, context, plan)"
      expect { batch_config.define(:name) { |a:| } }.to raise_error "Option :name value should not accept keyword argument `a:`"

      expect { batch_config.define(:name, proc {}) }.to raise_error "Batch loader should have 1 to 3 parameters (keys, context, plan)"
      expect { batch_config.define(:name, proc { |a| }) }.not_to raise_error
      expect { batch_config.define(:name, proc { |a, b| }) }.not_to raise_error
      expect { batch_config.define(:name, proc { |a, b, c| }) }.not_to raise_error
      expect { batch_config.define(:name, proc { |a, b, c, d| }) }.not_to raise_error
      expect { batch_config.define(:name, proc { |a:| }) }.to raise_error "Option :name value should not accept keyword argument `a:`"

      expect { batch_config.define(:name, lambda {}) }.to raise_error "Batch loader should have 1 to 3 parameters (keys, context, plan)"
      expect { batch_config.define(:name, lambda { |a| }) }.not_to raise_error
      expect { batch_config.define(:name, lambda { |a, b| }) }.not_to raise_error
      expect { batch_config.define(:name, lambda { |a, b, c| }) }.not_to raise_error
      expect { batch_config.define(:name, lambda { |a, b, c, d| }) }.to raise_error "Batch loader should have 1 to 3 parameters (keys, context, plan)"
      expect { batch_config.define(:name, lambda { |a:| }) }.to raise_error "Option :name value should not accept keyword argument `a:`"
    end
  end

  describe "#fetch_loader" do
    it "returns defined loader by name" do
      loader = proc { |a| }
      batch_config.define(:name, &loader)
      expect(batch_config.fetch_loader(:name)).to eq loader
    end

    it "raises error when loader was not found" do
      expect { batch_config.fetch_loader(:name) }.to raise_error Serega::SeregaError,
        "Batch loader with name `:name` was not defined. Define example: config.batch.define(:name) { |keys| ... }"
    end
  end

  describe "#loaders" do
    it "returns defined loaders hash" do
      loader = proc { |a| }
      batch_config.define(:name, &loader)
      expect(batch_config.loaders).to eq(name: loader)
    end
  end

  describe "#auto_hide" do
    it "returns auto_hide option" do
      batch_config.opts[:auto_hide] = "AUTO_HIDE"
      expect(batch_config.auto_hide).to eq "AUTO_HIDE"
    end
  end

  describe "#auto_hide=" do
    it "changes auto_hide option" do
      batch_config.opts[:auto_hide] = "AUTO_HIDE"
      batch_config.auto_hide = true
      expect(batch_config.auto_hide).to be true
    end

    it "validates argument" do
      expect { batch_config.auto_hide = 1 }
        .to raise_error Serega::SeregaError, "Must have boolean value, 1 provided"
    end
  end

  describe "#default_key" do
    it "returns default_key option" do
      batch_config.opts[:default_key] = "DEFAULT_KEY"
      expect(batch_config.default_key).to eq "DEFAULT_KEY"
    end
  end

  describe "#default_key=" do
    it "changes default_key option" do
      batch_config.opts[:default_key] = "DEFAULT_KEY"
      batch_config.default_key = :foo
      expect(batch_config.default_key).to eq :foo
    end

    it "validates argument" do
      expect { batch_config.default_key = 1 }
        .to raise_error Serega::SeregaError, "Must be a Symbol, 1 provided"
    end
  end
end
