# frozen_string_literal: true

class Serega
  module SeregaValidations
    #
    # Validations Utilities
    #
    module Utils
      #
      # Utility to check that callable object has no required keyword arguments
      #
      class CheckExtraKeywordArg
        # Checks hash keys are allowed
        #
        # @param option_name [Symbol] Option name
        # @param callable [#call] Callable object
        #
        # @raise [Serega::SeregaError] error if callable accepts required keyword argument
        #
        # @return [void]
        def self.call(option_name, callable)
          parameters = callable.is_a?(Proc) ? callable.parameters : callable.method(:call).parameters

          parameters.each do |parameter|
            next unless parameter[0] == :keyreq

            raise Serega::SeregaError, "Option #{option_name.inspect} value should not accept keyword argument `#{parameter[1]}:`"
          end
        end
      end
    end
  end
end
