# frozen_string_literal: true

require "support/activerecord"

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch::BatchConfig do
  let(:batch_config) { described_class.new({loaders: {}}) }

  let(:params_count_error) do
    "Batch loader can have maximum 3 parameters (keys, context, plan)"
  end

  let(:keyword_error) do
    "Invalid batch loader `name`. It should not have any required keyword arguments"
  end

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

    it "checks extra keyword arguments" do
      expect { batch_config.define(:name) { |a:| } }.to raise_error Serega::SeregaError, keyword_error
    end

    it "checks loader params_count is 1, 2 or 3" do
      value = proc {}
      counter = Serega::SeregaUtils::ParamsCount
      allow(counter).to receive(:call).and_return(0, 1, 2, 3, 4)

      expect { batch_config.define(:name, &value) }.not_to raise_error
      expect { batch_config.define(:name, &value) }.not_to raise_error
      expect { batch_config.define(:name, &value) }.not_to raise_error
      expect { batch_config.define(:name, &value) }.not_to raise_error
      expect { batch_config.define(:name, &value) }.to raise_error Serega::SeregaError, params_count_error

      expect(counter).to have_received(:call).with(value, max_count: 3).exactly(5).times
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
