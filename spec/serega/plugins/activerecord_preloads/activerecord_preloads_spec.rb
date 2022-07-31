# frozen_string_literal: true

load_plugin_code :activerecord_preloads

RSpec.describe Serega::SeregaPlugins::ActiverecordPreloads do
  it "loads preloads plugin" do
    new_class = Class.new(Serega)
    new_class.plugin :activerecord_preloads

    expect(new_class.plugin_used?(:preloads)).to be true
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

      expect(serializer.to_h(object)[:itself]).to be object
    end

    it "skips preloading for empty array" do
      object = []
      serializer = serializer_class.new
      expect(serializer.to_h(object, {many: false})[:itself]).to be object
    end

    it "skips preloading when nothing to preload" do
      object = "OBJECT"
      serializer = serializer_class.new
      allow(serializer).to receive(:preloads).and_return({})

      expect(serializer.to_h(object)[:itself]).to be object
    end
  end
end
