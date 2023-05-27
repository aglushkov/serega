# frozen_string_literal: true

load_plugin_code :preloads

RSpec.describe Serega::SeregaPlugins::Preloads do
  let(:serializer_class) { Class.new(Serega) { plugin :preloads } }

  describe "AttributeMethods" do
    it "sets attribute normalized preloads" do
      attribute = serializer_class.attribute :name, preload: :foo
      expect(attribute.preloads).to eq(foo: {})
      expect(attribute.preloads).to equal attribute.preloads
    end

    it "sets attribute normalized preloads_path" do
      attribute = serializer_class.attribute :name, preload: :foo
      expect(attribute.preloads_path).to eq([:foo])
      expect(attribute.preloads_path).to equal attribute.preloads_path
    end
  end
end
