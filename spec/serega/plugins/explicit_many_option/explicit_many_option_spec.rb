# frozen_string_literal: true

load_plugin_code :explicit_many_option

RSpec.describe Serega::SeregaPlugins::ExplicitManyOption do
  let(:base_serializer) do
    Class.new(Serega) do
      plugin :explicit_many_option
    end
  end

  describe "Validations" do
    it "adds CheckOptMany validator" do
      allow(described_class::CheckOptMany).to receive(:call)
      base_serializer.attribute :foo, many: true, serializer: "foo"
      expect(described_class::CheckOptMany).to have_received(:call).with(many: true, serializer: "foo")
    end

    describe described_class::CheckOptMany do
      it "require to set :many option for attributes with serializer" do
        expect { described_class.call(serializer: "foo") }
          .to raise_error Serega::SeregaError,
            "Attribute option :many [Boolean] must be provided" \
            " for attributes with :serializer option"
      end

      it "does not require to set :many option for attributes without serializer" do
        expect { described_class.call({}) }.not_to raise_error
      end

      it "allows when :many option exists for attributes with serializer" do
        expect { described_class.call({serializer: "foo", many: false}) }.not_to raise_error
      end
    end
  end
end
