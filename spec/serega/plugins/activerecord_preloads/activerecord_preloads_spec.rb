# frozen_string_literal: true

load_plugin_code :activerecord_preloads

RSpec.describe Serega::SeregaPlugins::ActiverecordPreloads do
  describe "loading" do
    let(:serializer) { Class.new(Serega) }

    it "loads successfully" do
      expect { serializer.plugin(:activerecord_preloads) }.not_to raise_error
    end

    it "loads additionally preloads plugin" do
      new_class = Class.new(Serega)
      new_class.plugin :activerecord_preloads

      expect(new_class.plugin_used?(:preloads)).to be true
    end

    it "loads activerecord_preloads successfully after preloads plugin" do
      new_class = Class.new(Serega)
      new_class.plugin :preloads
      new_class.plugin :activerecord_preloads

      expect(new_class.plugin_used?(:preloads)).to be true
      expect(new_class.plugin_used?(:activerecord_preloads)).to be true
    end

    it "raises error if loaded after :batch plugin" do
      serializer.plugin(:batch)
      error = "Plugin `activerecord_preloads` must be loaded before `batch`"
      expect { serializer.plugin(:activerecord_preloads) }.to raise_error Serega::SeregaError, error
    end
  end

  describe "InstanceMethods" do
    let(:serializer_class) do
      Class.new(Serega) do
        plugin :activerecord_preloads

        attribute :itself
      end
    end

    it "adds preloads to object when calling to_h" do
      object = "OBJ"
      preloads = "PRELOADS"
      serializer = serializer_class.new
      allow(serializer).to receive(:preloads).and_return(preloads)

      allow(Serega::SeregaPlugins::ActiverecordPreloads::Preloader)
        .to receive(:preload)
        .with(object, preloads)
        .and_return("OBJ_WITH_PRELOADS")

      expect(serializer.to_h(object)[:itself]).to eq("OBJ_WITH_PRELOADS")
    end

    it "skips preloading for nil" do
      object = nil
      serializer = serializer_class.new
      allow(serializer).to receive(:preloads)

      expect(serializer.to_h(object)).to be_nil
      expect(serializer).not_to have_received(:preloads)
    end

    it "skips preloading for empty array" do
      object = []
      serializer = serializer_class.new
      allow(serializer).to receive(:preloads)

      expect(serializer.to_h(object, {many: false})[:itself]).to be object
      expect(serializer).not_to have_received(:preloads)
    end

    it "skips preloading when nothing to preload" do
      object = "OBJECT"
      serializer = serializer_class.new
      allow(serializer).to receive(:preloads).and_return({})

      expect(serializer.to_h(object)[:itself]).to be object
      expect(serializer).to have_received(:preloads)
    end
  end
end
