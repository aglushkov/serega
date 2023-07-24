# frozen_string_literal: true

load_plugin_code :explicit_many_option

RSpec.describe Serega::SeregaPlugins::ExplicitManyOption do
  let(:base_serializer) do
    Class.new(Serega) do
      plugin :explicit_many_option
    end
  end

  describe "Validations" do
    describe "CheckMany" do
      it "require to set :many option for attributes with serializer" do
        expect { base_serializer.attribute :foo, serializer: base_serializer }
          .to raise_error Serega::SeregaError,
            "Attribute option :many [Boolean] must be provided" \
            " for attributes with :serializer option"
      end
    end
  end
end
