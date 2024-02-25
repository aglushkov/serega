# frozen_string_literal: true

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch do
  context "with if plugin" do
    let(:user_serializer) do
      Class.new(Serega) do
        plugin :if
        plugin :batch
        config.batch.define(:self) do |keys|
          keys.each_with_object({}) { |key, obj| obj[key] = key }
        end

        attribute :first_name
        attribute :post, batch: {id_method: :post_id, loader: :self}, if_value: proc { |value| value.odd? }
      end
    end

    let(:users) do
      [
        double(first_name: "USER1", post_id: 123),
        double(first_name: "USER2", post_id: 234)
      ]
    end

    it "returns correct data without conditionally skipped keys" do
      expect(user_serializer.to_h(users)).to eq(
        [
          {first_name: "USER1", post: 123},
          {first_name: "USER2"} # post: 234 must be skipped, as it is not :odd?
        ]
      )
    end
  end
end
