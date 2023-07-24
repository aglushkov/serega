# frozen_string_literal: true

class Serega
  #
  # Utility class to build OpenAPI schemas
  #
  class OpenAPI
    #
    # Constructs OpenAPI schemas for multiple serializers
    #
    # @params serializers [Class<Serega>] Serializers tobuild schemas,
    #   by default it is all serializers with :openapi plugin enabled
    #
    # @return [Hash] Schemas hash
    #
    def self.schemas(serializers = self.serializers)
      serializers.each_with_object({}) do |serializer_class, schemas|
        schema = serializer_class.openapi_schema
        schema_name = serializer_class.openapi_schema_name
        schemas[schema_name] = schema
      end
    end

    #
    # Returns list of serializers with :openapi plugin
    #
    def self.serializers
      @serializers ||= []
    end
  end

  module SeregaPlugins
    #
    # Plugin :openapi
    #
    # Helps to build OpenAPI schemas
    #
    # This schemas can be easielty used with "rswag" gem by adding them to "config.swagger_docs"
    #   https://github.com/rswag/rswag#referenced-parameters-and-schema-definitions
    #
    # This plugin only adds type "object" or "array" for relationships and marks
    # attributes as **required** if they have no :hide option set.
    #
    # OpenAPI properties will have no any "type" or other options specified by default,
    # you should provide them in 'YourSerializer.openapi_properties' method.
    # `openapi_properties` can be specified multiple time, in this case they wil be merged.
    #
    # After enabling this plugin attributes with :serializer option will have
    # to have :many option set to construct "object" or "array" openapi type for relationships.
    #
    # OpenAPI `$ref` property will be added automatically for all relationships.
    #
    # Example constructing all serializers schemas:
    #   `Serega::OpenAPI.schemas`
    #
    # Example constructing specific serializers schemas:
    #   `Serega::OpenAPI.schemas(Serega::OpenAPI.serializers - [MyBaseSerializer])`
    #
    # Example constructing one serializer schema:
    #   `SomeSerializer.openapi_schema`
    #
    # @example
    #   class BaseSerializer < Serega
    #     plugin :openapi
    #   end
    #
    #   class UserSerializer < BaseSerializer
    #     attribute :name
    #
    #     openapi_properties(
    #       name: { type: :string }
    #     )
    #   end
    #
    #   class PostSerializer < BaseSerializer
    #     attribute :text
    #     attribute :user, serializer: UserSerializer, many: false
    #     attribute :comments, serializer: PostSerializer, many: true, hide: true
    #
    #     openapi_properties(
    #       text: { type: :string },
    #       user: { type: 'object' }, # `$ref` option will be added automatically when constructing schema
    #       comments: { type: 'array' } # `items` option with `$ref` will be added automatically when constructing schema
    #     )
    #   end
    #
    #   puts Serega::OpenAPI.schemas
    #   =>
    #   {
    #     "PostSerializer" => {
    #       type: "object",
    #       properties: {
    #         text: {type: "string"},
    #         user: {:$ref => "#/components/schemas/UserSerializer"},
    #         comments: {type: "array", items: {:$ref => "#/components/schemas/PostSerializer"}}
    #       },
    #       required: [:text, :comments],
    #       additionalProperties: false
    #     },
    #     "UserSerializer" => {
    #       type: "object",
    #       properties: {
    #         name: {type: "string"}
    #       },
    #       required: [:name],
    #       additionalProperties: false
    #     }
    #   }
    #
    module OpenAPI
      DEFAULT_SCHEMA_NAME_BUILDER = ->(serializer_class) { serializer_class.name }
      DEFAULT_REF_BUILDER = ->(serializer_class) { "#/components/schemas/#{serializer_class.openapi_schema_name}" }

      # @return [Symbol] Plugin name
      def self.plugin_name
        :openapi
      end

      # Checks requirements and loads additional plugins
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.before_load_plugin(serializer_class, **opts)
        unless serializer_class.plugin_used?(:explicit_many_option)
          serializer_class.plugin :explicit_many_option
        end
      end

      #
      # Applies plugin code to specific serializer
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **opts)
        require_relative "./lib/modules/config"
        require_relative "./lib/openapi_config"

        serializer_class.extend(ClassMethods)
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)

        config = serializer_class.config
        config.opts[:openapi] = {properties: {}}
        openapi_config = serializer_class.config.openapi
        openapi_config.schema_name_builder = opts[:schema_name_builder] || DEFAULT_SCHEMA_NAME_BUILDER
        openapi_config.ref_builder = opts[:ref_builder] || DEFAULT_REF_BUILDER
      end

      #
      # Adds config options and runs other callbacks after plugin was loaded
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.after_load_plugin(serializer_class, **opts)
        Serega::OpenAPI.serializers << serializer_class unless serializer_class.equal?(Serega)
      end

      #
      # Serega additional/patched class methods
      #
      # @see Serega
      #
      module ClassMethods
        #
        # OpenAPI schema for current serializer
        #
        def openapi_schema
          properties = SeregaUtils::EnumDeepDup.call(openapi_properties)
          required_properties = []

          attributes.each do |attribute_name, attribute|
            add_openapi_property(properties, attribute_name, attribute)
            add_openapi_required_property(required_properties, attribute_name, attribute)
          end

          {
            type: "object",
            properties: properties,
            required: required_properties,
            additionalProperties: false
          }
        end

        #
        # Adds new OpenAPI properties and returns all properties
        #
        # @param props [Hash] Specifies new properties
        #
        # @return [Hash] Specified OpenAPI properties
        #
        def openapi_properties(props = FROZEN_EMPTY_HASH)
          config.openapi.properties(props)
        end

        #
        # Builds OpenAPI schema name using configured builder
        #
        # @return [String] OpenAPI schema name
        #
        def openapi_schema_name
          config.openapi.schema_name_builder.call(self)
        end

        private

        def inherited(subclass)
          super
          Serega::OpenAPI.serializers << subclass
        end

        def add_openapi_property(properties, attribute_name, attribute)
          property = properties[attribute_name] ||= {}
          return unless attribute.relation?

          ref = attribute.serializer.config.openapi.ref_builder.call(attribute.serializer)

          if attribute.many
            property[:type] = "array"
            property[:items] ||= {}
            property[:items][:$ref] ||= ref
          else
            property[:$ref] ||= ref
          end
        end

        def add_openapi_required_property(required_properties, attribute_name, attribute)
          required_properties << attribute_name unless attribute.hide
        end
      end
    end

    register_plugin(OpenAPI.plugin_name, OpenAPI)
  end
end
