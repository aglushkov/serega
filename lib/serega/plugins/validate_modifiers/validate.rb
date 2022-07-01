# frozen_string_literal: true

class Serega
  module Plugins
    module ValidateModifiers
      class Validate
        class << self
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

            raise Serega::Error, "Attribute #{field_name} not exists"
          end

          def raise_nested_error(name, prev_names, nested_fields)
            field_name = field_name(name, prev_names)
            first_nested = nested_fields.keys.first

            raise Serega::Error, "Attribute #{field_name} is not a relation to add '#{first_nested}' attribute"
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
