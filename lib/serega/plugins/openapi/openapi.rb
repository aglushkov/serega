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
        next if schema.empty?

        id = serializer_class.openapi_schema_name
        schemas[id] = schema
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
    # OpenAPI properties will have no any "type" or other limits specified by default,
    # you should provide them as attribute :openapi option.
    #
    # This plugin only adds type "object" or "array" for relationships and marks
    # attributes as **required** if they have no :hide option set.
    #
    # After enabling this plugin attributes with :serializer option will have
    # to have :many option set to construct "object" or "array" openapi type.
    #
    # Example constructing all serializers schemas: "Serega::OpenAPI.schemas"
    #
    # Example constructing specific serializers schemas: "Serega::OpenAPI.schemas(serializers_classes_array)"
    #
    # Example constructing one serializer schema: "SomeSerializer.openapi_schema"
    #
    # @example
    #   class BaseSerializer < Serega
    #     plugin :openapi
    #   end
    #
    #   class UserSerializer < BaseSerializer
    #     attribute :name, openapi: { type: "string" }
    #   end
    #
    #   class PostSerializer < BaseSerializer
    #     attribute :text, openapi: { type: "string" }
    #     attribute :user, serializer: UserSerializer, many: false
    #     attribute :comments, serializer: PostSerializer, many: true, hide: true
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
      # @return [Symbol] Plugin name
      def self.plugin_name
        :openapi
      end

      #
      # Applies plugin code to specific serializer
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **_opts)
        require_relative "./validations/check_opt_many"

        serializer_class.extend(ClassMethods)
        serializer_class::SeregaAttribute.include(AttributeInstanceMethods)
        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)
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
        Serega::OpenAPI.serializers << serializer_class

        config = serializer_class.config
        config.attribute_keys << :openapi
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
          return FROZEN_EMPTY_HASH if attributes.empty?

          properties = {}
          required_properties = []

          attributes.each do |attribute_name, attribute|
            properties[attribute_name] = attribute.openapi_opts
            required_properties << attribute_name unless attribute.hide
          end

          {
            type: "object",
            properties: properties,
            required: required_properties,
            additionalProperties: false
          }
        end

        #
        # Name of openapi schema for current serializer.
        #   It will be used also in $ref links to this schema
        #
        def openapi_schema_name
          name
        end

        private

        def inherited(subclass)
          super
          Serega::OpenAPI.serializers << subclass
        end
      end

      #
      # Serega::SeregaAttribute additional/patched instance methods
      #
      # @see Serega::SeregaAttribute::AttributeInstanceMethods
      #
      module AttributeInstanceMethods
        #
        # Options for openapi schema property
        #
        def openapi_opts
          opts = initials[:opts][:openapi]
          return opts unless opts.nil? # return custom opts if provided (including false value)
          return FROZEN_EMPTY_HASH if !relation?

          ref = "#/components/schemas/#{serializer.openapi_schema_name}"
          many ? {type: "array", items: {"$ref": ref}} : {"$ref": ref}
        end
      end

      #
      # Serega::SeregaValidations::CheckAttributeParams additional/patched class methods
      #
      # @see Serega::SeregaValidations::CheckAttributeParams
      #
      module CheckAttributeParamsInstanceMethods
        private

        def check_opts
          super

          CheckOptMany.call(opts)
        end
      end
    end

    register_plugin(OpenAPI.plugin_name, OpenAPI)
  end
end
