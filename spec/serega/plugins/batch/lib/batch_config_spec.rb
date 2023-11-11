# frozen_string_literal: true

require "support/activerecord"

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch::BatchConfig do
  let(:batch_config) { described_class.new({loaders: {}}) }

  let(:params_count_error) do
    "Batch loader can have maximum 3 parameters (ids, context, plan)"
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

    it "checks loader has maximum 3 args" do
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

  describe "#id_method" do
    it "returns id_method option" do
      batch_config.opts[:id_method] = "id_method"
      expect(batch_config.id_method).to eq "id_method"
    end
  end

  describe "#id_method=" do
    it "changes id_method option" do
      batch_config.opts[:id_method] = "id_method"
      batch_config.id_method = :foo
      expect(batch_config.id_method).to eq :foo
    end

    it "validates argument" do
      expect { batch_config.id_method = 1 }
        .to raise_error Serega::SeregaError, "Invalid :batch option :id_method. It must be a Symbol, a Proc or respond to #call"
    end
  end
end
