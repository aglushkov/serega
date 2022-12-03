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
        class << self
          # Validates provided fields names are existing attributes
          #
          # @param serializer_class [Serega]
          # @param fields [Hash] validated fields
          #
          # @raise [Serega::AttributeNotExist] when modifier not exist as attribute
          #
          # @return [void]
          #
          def call(serializer_class, fields)
            return unless fields

            validate(serializer_class, fields, [])
          end

          private

          def validate(serializer_class, fields, prev_names)
            fields.each do |name, nested_fields|
              attribute = serializer_class.attributes[name]

              raise_error(name, prev_names) unless attribute
              next if nested_fields.empty?

              raise_nested_error(name, prev_names, nested_fields) unless attribute.relation?
              nested_serializer = attribute.serializer
              validate(nested_serializer, nested_fields, prev_names + [name])
            end
          end

          def raise_error(name, prev_names)
            field_name = field_name(name, prev_names)

            raise Serega::AttributeNotExist, "Attribute #{field_name} not exists"
          end

          def raise_nested_error(name, prev_names, nested_fields)
            field_name = field_name(name, prev_names)
            first_nested = nested_fields.keys.first

            raise Serega::AttributeNotExist, "Attribute #{field_name} has no :serializer option specified to add nested '#{first_nested}' attribute"
          end

          def field_name(name, prev_names)
            res = "'#{name}'"
            res += " ('#{prev_names.join(".")}.#{name}')" if prev_names.any?
            res
          end
        end
      end
    end
  end
end
