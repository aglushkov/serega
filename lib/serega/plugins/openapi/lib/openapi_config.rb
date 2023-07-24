# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module OpenAPI
      #
      # OpenAPI plugin config
      #
      class OpenAPIConfig
        attr_reader :serializer_class, :opts

        def initialize(serializer_class, opts)
          @serializer_class = serializer_class
          @opts = opts
        end

        #
        # Saves new properties
        #
        # @param new_properties [Hash] new properties
        #
        # @return [Hash] OpenAPI properties
        #
        def properties(new_properties = FROZEN_EMPTY_HASH)
          properties = opts[:properties]
          return properties if new_properties.empty?

          new_properties = SeregaUtils::EnumDeepDup.call(new_properties)
          symbolize_keys!(new_properties)

          new_properties.each do |attribute_name, new_attribute_properties|
            check_attribute_exists(attribute_name)
            check_properties_is_a_hash(attribute_name, new_attribute_properties)

            properties[attribute_name] = symbolize_keys!(new_attribute_properties)
          end
        end

        #
        # @return [#call] builder of `$ref` attribute
        #
        def ref_builder
          opts[:ref_builder]
        end

        #
        # Sets new $ref option builder
        #
        # @param builder [#call] Callable object that accepts serializer_class and constructs $ref option string
        #
        # @return Specified new builder
        #
        def ref_builder=(builder)
          raise SeregaError, "ref_builder must respond to #call" unless builder.respond_to?(:call)
          opts[:ref_builder] = builder
        end

        #
        # @return [#call] builder of schema name
        #
        def schema_name_builder
          opts[:schema_name_builder]
        end

        #
        # Sets new schema_name_builder
        #
        # @param builder [#call] Callable object that accepts serializer_class and
        #   constructs schema name to use in schemas list and in $ref option
        #
        # @return Specified new builder
        #
        def schema_name_builder=(builder)
          raise SeregaError, "schema_name_builder must respond to #call" unless builder.respond_to?(:call)
          opts[:schema_name_builder] = builder
        end

        private

        def check_attribute_exists(attribute_name)
          return if serializer_class.attributes.key?(attribute_name)

          raise SeregaError, "No attribute with name :#{attribute_name}"
        end

        def check_properties_is_a_hash(attribute_name, new_attribute_properties)
          return if new_attribute_properties.is_a?(Hash)

          raise SeregaError, "Property #{attribute_name} value must be a Hash," \
            " but #{new_attribute_properties.inspect} was provided"
        end

        def symbolize_keys!(opts)
          opts.transform_keys! do |key|
            key.to_sym
          end
        end
      end
    end
  end
end
