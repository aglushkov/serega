# frozen_string_literal: true

load_plugin_code :openapi

RSpec.describe Serega::SeregaPlugins::OpenAPI do
  let(:base_serializer) do
    Class.new(Serega) do
      plugin :openapi
    end
  end

  describe "loading" do
    it "loads additionally :explicit_many_option plugin" do
      expect(base_serializer.plugin_used?(:explicit_many_option)).to be true
    end

    it "works when :explicit_many_option plugin is already loaded" do
      expect {
        Class.new(Serega) do
          plugin :explicit_many_option
          plugin :openapi
        end
      }.not_to raise_error
    end

    it "adds serializer to OpenAPI serializers list" do
      Serega::OpenAPI.serializers.clear
      base_serializer
      expect(Serega::OpenAPI.serializers).to eq [base_serializer]
    end

    it "does not add Serega main class OpenAPI serializers list" do
      Serega::OpenAPI.serializers.clear

      # Overwrite equality check to not load plugin to Serega, as it will broke other tests
      #   Serega.plugin :openapi
      Class.new(Serega) do
        def self.equal?(other)
          other == Serega
        end

        plugin :openapi
      end

      expect(Serega::OpenAPI.serializers).to eq []
    end
  end

  describe "configuration" do
    it "configures default schema_name builder" do
      expect(base_serializer.config.openapi.schema_name_builder).to eq described_class::DEFAULT_SCHEMA_NAME_BUILDER
    end

    it "configures default $ref option builder" do
      expect(base_serializer.config.openapi.ref_builder).to eq described_class::DEFAULT_REF_BUILDER
    end

    it "allows to configure to schema_name_builder when loading plugin" do
      builder = proc {}
      serializer = Class.new(Serega) { plugin :openapi, schema_name_builder: builder }
      expect(serializer.config.openapi.schema_name_builder).to equal builder
    end

    it "allows to configure to $ref option builder when loading plugin" do
      builder = proc {}
      serializer = Class.new(Serega) { plugin :openapi, ref_builder: builder }
      expect(serializer.config.openapi.ref_builder).to equal builder
    end

    it "raises error when not callable value is set as schema_name_builder" do
      expect { Class.new(Serega) { plugin :openapi, schema_name_builder: "" } }
        .to raise_error Serega::SeregaError, "schema_name_builder must respond to #call"
    end

    it "raises error when not callable value is set as ref_builder" do
      expect { Class.new(Serega) { plugin :openapi, ref_builder: "" } }
        .to raise_error Serega::SeregaError, "ref_builder must respond to #call"
    end
  end

  describe "ConfigMethods" do
    describe "#openapi" do
      it "returns OpenAPIConfig object" do
        expect(base_serializer.config.openapi).to be_a described_class::OpenAPIConfig
      end
    end
  end

  describe described_class::OpenAPIConfig do
    let(:serializer) do
      Class.new(base_serializer) do
        attribute :attr1
        attribute :attr2
      end
    end

    let(:config) { serializer.config.openapi }

    describe "#properties" do
      it "returns current properties" do
        expect(config.properties).to eq({})
      end

      it "saves properties" do
        config.properties(attr1: {type: "string"})
        expect(config.properties).to eq(attr1: {type: "string"})
      end

      it "saves properties with simbolized keys" do
        config.properties("attr1" => {"type" => "string"})
        expect(config.properties).to eq(attr1: {type: "string"})
      end

      it "merges properties" do
        config.properties(attr1: {type: "string"})
        config.properties(attr2: {type: "integer"})

        expect(config.properties).to eq(
          attr1: {type: "string"},
          attr2: {type: "integer"}
        )
      end

      it "raises error if no attribute with defined property" do
        expect { config.properties(foobar: {}) }
          .to raise_error Serega::SeregaError, "No attribute with name :foobar"
      end

      it "raises error property value is not a Hash" do
        expect { config.properties(attr1: "string") }
          .to raise_error Serega::SeregaError, "Property attr1 value must be a Hash, but \"string\" was provided"
      end
    end
  end

  describe "ClassMethods" do
    describe ".inherited" do
      it "saves serializer to list of OpenAPI serializers except Serega main class" do
        Serega::OpenAPI.serializers.clear

        base_serializer
        expect(Serega::OpenAPI.serializers).to eq [base_serializer]

        new_serializer = Class.new(base_serializer)
        expect(Serega::OpenAPI.serializers).to eq [base_serializer, new_serializer]
      end
    end

    describe ".openapi_schema" do
      it "returns empty object schema for serializer without attributes" do
        user_serializer = Class.new(base_serializer)
        expect(user_serializer.openapi_schema).to eq(
          type: "object",
          properties: {},
          required: [],
          additionalProperties: false
        )
      end

      it "returns required property for not hidden attribute" do
        user_serializer = Class.new(base_serializer) do
          attribute :name
        end

        expect(user_serializer.openapi_schema).to include(
          properties: {name: {}},
          required: [:name]
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

      it "returns options set in openapi_properties" do
        user_serializer = Class.new(base_serializer) do
          attribute :name

          openapi_properties(
            name: {type: :string}
          )
        end

        expect(user_serializer.openapi_schema).to include(
          properties: {name: {type: :string}}
        )
      end

      it "returns $ref for relationship with many: false" do
        child_serializer = Class.new(base_serializer)
        child_serializer.config.openapi.ref_builder = proc { "ref" }

        user_serializer = Class.new(base_serializer) do
          attribute :child, serializer: child_serializer, many: false
        end

        expect(user_serializer.openapi_schema).to include(
          properties: {child: {"$ref": "ref"}}
        )
      end

      it "returns type=array and items with $ref for relationship with many: true" do
        child_serializer = Class.new(base_serializer)
        child_serializer.config.openapi.ref_builder = proc { "ref" }

        user_serializer = Class.new(base_serializer) do
          attribute :children, serializer: child_serializer, many: true
        end

        expect(user_serializer.openapi_schema).to include(
          properties: {children: {type: "array", items: {"$ref": "ref"}}}
        )
      end
    end

    describe ".openapi_schema_name" do
      it "returns serializer name by default" do
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
          attribute :title
          attribute :user, serializer: users, many: false

          openapi_properties(title: {type: "string"})
        end
      end

      before do
        described_class.serializers.clear
        allow(base_serializer).to receive(:name).and_return("base")
        allow(user_serializer).to receive(:name).and_return("users")
        allow(post_serializer).to receive(:name).and_return("posts")
      end

      it "returns schemas for all serializers" do
        expect(described_class.schemas).to eq(
          "base" => {
            type: "object",
            properties: {},
            required: [],
            additionalProperties: false
          },
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

      it "returns schemas for provided serializers" do
        schemas = described_class.schemas(described_class.serializers - [base_serializer])
        expect(schemas.length).to eq 2
        expect(schemas).to include("posts")
        expect(schemas).to include("users")
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
