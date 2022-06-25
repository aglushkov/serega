# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::Plugins::Preloads::CheckOptPreloadPath do
  let(:validator) { described_class }

  it "does not raise error when no preload_path option" do
    expect { validator.call({}) }.not_to raise_error
  end

  it "raises error when :preload_path option provided without :preload option" do
    expect { validator.call({preload_path: :foo}) }
      .to raise_error Serega::Error, "Invalid option :preload_path => :foo. Can be provided only when :preload option provided"
  end

  it "raises error when :preload_path option provided without :serializer option" do
    expect { validator.call({preload_path: :foo, preload: :foo}) }
      .to raise_error Serega::Error, "Invalid option :preload_path => :foo. Can be provided only when :serializer option provided"
  end

  it "raises error when :preload_path option is not included in :preload option" do
    expect { validator.call({preload_path: :foo, preload: {bar: :bazz}, serializer: :foo}) }
      .to raise_error Serega::Error, "Invalid option :preload_path => :foo. Can be one of [:bar], [:bar, :bazz]"
  end

  it "does not raises error with valid :preload_path" do
    expect { validator.call({preload_path: :foo, preload: %i[foo bar], serializer: :foo}) }
      .not_to raise_error
  end
end
