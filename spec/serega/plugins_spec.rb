# frozen_string_literal: true

RSpec.describe Serega::Plugins do
  let(:described_module) { described_class }

  describe ".register_plugin" do
    it "adds plugin to the @plugins list" do
      plugin = Module.new
      plugin_name = :new_plugin
      described_module.register_plugin(plugin_name, plugin)
      registered_plugin = described_module.instance_variable_get(:@plugins).fetch(plugin_name)

      expect(registered_plugin).to eq plugin
    end
  end

  describe ".find_plugin" do
    it "returns module if module provided" do
      plugin = Module.new
      expect(described_module.find_plugin(plugin)).to eq plugin
    end

    it "returns already registered plugin found by name" do
      plugin = Module.new
      plugin_name = :new_plugin
      described_module.register_plugin(plugin_name, plugin)

      expect(described_module.find_plugin(plugin_name)).to eq plugin
    end

    it "returns global plugins found by name" do
      expect(described_module.find_plugin(:root).name).to eq "#{described_module}::Root"
      expect(described_module.find_plugin(:metadata).name).to eq "#{described_module}::Metadata"
    end

    it "raises specific error if plugin not found" do
      expect { described_module.find_plugin(:foo) }
        .to raise_error Serega::Error, "Plugin 'foo' does not exist"
    end

    it "raises specific error if plugin was found by name but was not registered" do
      plugin_name = "test_foo"

      # Add plugin folder and file in plugins directory
      plugin_dir = File.join(__dir__, "../../lib/serega/plugins", plugin_name)
      plugin_path = File.join(plugin_dir, "#{plugin_name}.rb")
      Dir.mkdir(plugin_dir)
      File.new(plugin_path, File::CREAT)

      expect { described_module.find_plugin(plugin_name) }
        .to raise_error Serega::Error, "Plugin '#{plugin_name}' did not register itself correctly"
    ensure
      File.unlink(plugin_path)
      Dir.unlink(plugin_dir)
    end
  end
end
