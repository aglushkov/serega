# frozen_string_literal: true

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch do
  context "with preloads plugin" do
    let(:user_serializer) do
      post_ser = post_serializer
      Class.new(Serega) do
        plugin :preloads, auto_preload_attributes_with_serializer: true
        plugin :batch

        attribute :one, batch: {key: :id, loader: :loader}, serializer: post_ser
        attribute :two, serializer: post_ser
        attribute :three, batch: {key: :id, loader: :loader}, serializer: post_ser, preload: :custom
      end
    end

    let(:post_serializer) do
      Class.new(Serega)
    end

    it "returns no preloads by default for attributes with `batch` option" do
      expect(user_serializer.attributes[:one].preloads).to be_nil
      expect(user_serializer.attributes[:two].preloads).to eq({two: {}})
    end

    it "keeps manually added preloads" do
      expect(user_serializer.attributes[:three].preloads).to eq({custom: {}})
    end
  end
end
