# frozen_string_literal: true

class Serega
  module SeregaValidations
    class CheckInitiateParams
      module InstanceMethods
        attr_reader :opts

        def initialize(opts)
          @opts = opts
        end

        def validate
          check_allowed_keys
          check_modifiers
        end

        private

        def check_allowed_keys
          Utils::CheckAllowedKeys.call(opts, serializer_class.config[:initiate_keys])
        end

        def check_modifiers
          Initiate::CheckModifiers.call(serializer_class, opts[:only])
          Initiate::CheckModifiers.call(serializer_class, opts[:except])
          Initiate::CheckModifiers.call(serializer_class, opts[:with])
        end

        def serializer_class
          self.class.serializer_class
        end
      end

      include InstanceMethods
      extend Serega::SeregaHelpers::SerializerClassHelper
    end
  end
end
