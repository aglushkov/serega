# frozen_string_literal: true

require "support/activerecord"

load_plugin_code :batch

RSpec.describe Serega::SeregaPlugins::Batch do
  let(:serializer) { Class.new(Serega) { plugin :batch } }

  describe "PlanPoint methods" do
    describe "#batch" do
      it "returns provided attribute #batch option" do
        attribute = serializer.attribute :foo,
          batch: {loader: proc {}, key: :id}

        batch = serializer::SeregaPlanPoint.new("plan", attribute, []).batch

        expect(batch).to eq attribute.batch
      end
    end
  end
end
