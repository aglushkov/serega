# frozen_string_literal: true

class Serega
  module SeregaValidations
    #
    # Validations that take place when initializing serializer
    #
    module Initiate
      #
      # Modifiers validation
      #
      class CheckModifiers
        #
        # Validates provided fields names are existing attributes
        #
        # @param serializer_class [Serega]
        # @param only [Hash, nil] `only` modifier
        # @param with [Hash, nil] `with` modifier
        # @param except [Hash, nil] `except` modifier
        #
        # @raise [Serega::AttributeNotExist] when some checked modifier has not existing attribute
        #
        # @return [void]
        #
        def call(serializer_class, only, with, except)
          validate(serializer_class, only) if only
          validate(serializer_class, with) if with
          validate(serializer_class, except) if except

          raise_errors if any_error?
        end

        private

        def validate(serializer_class, fields)
          fields.each do |name, nested_fields|
            attribute = serializer_class && serializer_class.attributes[name]

            # Save error when no attribute with checked name exists
            unless attribute
              save_error(name)
              next
            end

            # Return when attribute has no nested fields
            next if nested_fields.empty?

            with_parent_name(name) do
              validate(attribute.serializer, nested_fields)
            end
          end
        end

        def parents_names
          @parents_names ||= []
        end

        def with_parent_name(name)
          parents_names << name
          yield
          parents_names.pop
        end

        def error_attributes
          @error_attributes ||= []
        end

        def save_error(name)
          full_attribute_name = [*parents_names, name].join(".")
          error_attributes << full_attribute_name
        end

        def raise_errors
          raise Serega::AttributeNotExist, "Not existing attributes: #{error_attributes.join(", ")}"
        end

        def any_error?
          defined?(@error_attributes)
        end
      end
    end
  end
end
