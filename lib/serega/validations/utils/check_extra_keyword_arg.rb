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
        # @param callable [#call] Callable object
        # @param callable_description [Symbol] Callable object description
        #
        # @raise [Serega::SeregaError] error if callable accepts required keyword argument
        #
        # @return [void]
        def self.call(callable, callable_description)
          parameters = callable.is_a?(Proc) ? callable.parameters : callable.method(:call).parameters

          parameters.each do |parameter|
            next unless parameter[0] == :keyreq

            raise Serega::SeregaError, "Invalid #{callable_description}. It should not have any required keyword arguments"
          end
        end
      end
    end
  end
end
