# frozen_string_literal: true

load_plugin_code :openapi

RSpec.describe Serega::SeregaPlugins::OpenAPI do
  let(:base_serializer) do
    Class.new(Serega) do
      plugin :openapi
    end
  end

  describe "AttributeMethods" do
    describe "#openapi_opts" do
      it "returns provided property if it is not null" do
        attribute = base_serializer.attribute :foo, openapi: {type: "string"}
        expect(attribute.openapi_opts).to eq({type: "string"})
      end

      it "returns empty hash if provided null" do
        attribute_foo = base_serializer.attribute :foo
        attribute_bar = base_serializer.attribute :bar, openapi: nil
        expect(attribute_foo.openapi_opts).to eq({})
        expect(attribute_bar.openapi_opts).to eq({})
      end

      it "returns $rel attribute for relation with many: false option" do
        user_serializer = Class.new(base_serializer)
        allow(user_serializer).to receive(:openapi_schema_name).and_return("user")
        attribute = base_serializer.attribute :foo, serializer: user_serializer, many: false
        expect(attribute.openapi_opts).to eq({:$ref => "#/components/schemas/user"})
      end

      it "returns type=\"array\" for relation with many: true option" do
        user_serializer = Class.new(base_serializer)
        allow(user_serializer).to receive(:openapi_schema_name).and_return("user")
        attribute = base_serializer.attribute :foo, serializer: user_serializer, many: true
        expect(attribute.openapi_opts).to eq(type: "array", items: {:$ref => "#/components/schemas/user"})
      end
    end
  end

  describe "Validations" do
    describe "CheckMany" do
      it "require to set :many option for attributes with serializer" do
        expect { base_serializer.attribute :foo, serializer: base_serializer }
          .to raise_error Serega::SeregaError,
            "Attribute option :many [Boolean] must be provided" \
            " for attributes with :serializer option" \
            " when :openapi plugin added"
      end
    end
  end

  describe "ClassMethods" do
    describe ".openapi_schema" do
      it "returns schema for serializer" do
        user_serializer = Class.new(base_serializer) do
          attribute :name
        end

        expect(user_serializer.openapi_schema).to eq(
          type: "object",
          properties: {name: {}},
          required: [:name],
          additionalProperties: false
        )
      end

      it "returns not required property for hidden attribute" do
        user_serializer = Class.new(base_serializer) do
          attribute :name, hide: true
        end

        expect(user_serializer.openapi_schema).to include(
          properties: {name: {}},
          required: []
        )
      end

      it "returns empty hash schema for serializer without attributes" do
        user_serializer = Class.new(base_serializer)

        expect(user_serializer.openapi_schema).to eq({})
      end
    end

    describe ".openapi_schema_name" do
      it "returns serializer name" do
        user_serializer = Class.new(base_serializer) do
          def self.name
            "API::UserSerializer"
          end
        end

        expect(user_serializer.openapi_schema_name).to eq "API::UserSerializer"
      end
    end
  end

  describe Serega::OpenAPI do
    describe ".schemas" do
      let(:user_serializer) do
        Class.new(base_serializer) do
          attribute :name
        end
      end

      let(:post_serializer) do
        users = user_serializer

        Class.new(base_serializer) do
          attribute :title, openapi: {type: "string"}
          attribute :user, serializer: users, many: false
        end
      end

      before do
        described_class.serializers.clear
        allow(user_serializer).to receive(:openapi_schema_name).and_return("users")
        allow(post_serializer).to receive(:openapi_schema_name).and_return("posts")
      end

      it "returns schemas for all serializers" do
        expect(described_class.schemas).to eq(
          "posts" => {
            type: "object",
            properties: {title: {type: "string"}, user: {:$ref => "#/components/schemas/users"}},
            required: [:title, :user],
            additionalProperties: false
          },
          "users" => {
            type: "object",
            properties: {name: {}},
            required: [:name],
            additionalProperties: false
          }
        )
      end
    end

    describe ".serializers" do
      before { described_class.serializers.clear }

      it "returns list of serializers with :openapi plugin enabled" do
        expect(described_class.serializers).to eq []

        Class.new(Serega) # :openapi not enabled
        expect(described_class.serializers).to eq []

        class1 = Class.new(base_serializer) # nested from base_serilaizer with :openapi enabled
        expect(described_class.serializers).to eq [base_serializer, class1]

        class2 = Class.new(class1) # nested from base_serilaizer with :openapi enabled, level 2
        expect(described_class.serializers).to eq [base_serializer, class1, class2]

        # New serializer with :openapi
        class3 = Class.new(Serega) do
          plugin :openapi
        end

        expect(described_class.serializers).to eq [base_serializer, class1, class2, class3]
      end
    end
  end
end
