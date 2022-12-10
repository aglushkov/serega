# frozen_string_literal: true

class Serega
  module SeregaValidations
    #
    # Validations of serializer initialization options
    #
    class CheckInitiateParams
      #
      # Validations of serializer initialization options instance methods
      #
      module InstanceMethods
        # @return [Hash] validated initialization options
        attr_reader :opts

        #
        # Initializes validator for initialization options
        #
        # @param opts [Hash] initialization options
        #
        # @return [void]
        #
        def initialize(opts)
          @opts = opts
        end

        #
        # Validates initiating params
        #
        def validate
          check_allowed_keys
          check_modifiers
        end

        private

        def check_allowed_keys
          Utils::CheckAllowedKeys.call(opts, serializer_class.config.initiate_keys)
        end

        def check_modifiers
          Initiate::CheckModifiers.new.call(serializer_class, opts[:only], opts[:with], opts[:except])
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
