# frozen_string_literal: true

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch do
  context "with formatters plugin" do
    let(:user_serializer) do
      Class.new(Serega) do
        plugin :formatters
        plugin :batch

        attribute :first_name

        attribute :post, batch: {key: :post_id, loader: :to_s}
        attribute :post_reverse, batch: {key: :post_id, loader: :to_s}, format: proc { |value| value.reverse }

        config.batch.define(:to_s) do |keys|
          keys.zip(keys.map(&:to_s)).to_h
        end
      end
    end

    let(:users) do
      [
        double(first_name: "USER1", post_id: 123),
        double(first_name: "USER2", post_id: 234)
      ]
    end

    it "returns correctly formatted data" do
      expect(user_serializer.to_h(users)).to eq(
        [
          {first_name: "USER1", post: "123", post_reverse: "321"},
          {first_name: "USER2", post: "234", post_reverse: "432"}
        ]
      )
    end
  end
end
