# frozen_string_literal: true

class Serega
  module SeregaValidations
    #
    # Lazy loader parameters validators
    #
    class CheckLazyLoaderParams
      #
      # lazy_loader parameters validation instance methods
      #
      module InstanceMethods
        # @return [Symbol] validated lazy_loader name
        attr_reader :name

        # @return [nil, #call] validated lazy_loader value or block
        attr_reader :lazy_loader

        def initialize(name, lazy_loader)
          @name = name
          @lazy_loader = lazy_loader
        end

        #
        # Checks lazy loader parameters
        #
        # @raise [SeregaError] SeregaError that lazy loader has invalid arguments
        #
        # @return [void]
        #
        def validate
          check_name
          check_loader
        end

        private

        def check_name
          raise SeregaError, name_type_error if !name.is_a?(Symbol) && !name.is_a?(String)
        end

        def check_loader
          check_lazy_loader_type
          check_lazy_loader_args
        end

        def check_lazy_loader_type
          raise SeregaError, type_error if !lazy_loader.is_a?(Proc) && !lazy_loader.respond_to?(:call)
        end

        def check_lazy_loader_args
          signature = SeregaUtils::MethodSignature.call(lazy_loader, pos_limit: 2, keyword_args: [:ctx])
          raise SeregaError, arguments_error unless %w[1 2 1_ctx].include?(signature)
        end

        def name_type_error
          "Lazy loader name must be a Symbol or String"
        end

        def type_error
          "Lazy loader value must be a Proc or respond to #call"
        end

        def arguments_error
          <<~ERR.strip
            Lazy loader arguments should have one of this signatures:
            - (objects)       # one argument
            - (objects, :ctx) # one argument and one :ctx keyword argument
          ERR
        end
      end

      include InstanceMethods
      extend Serega::SeregaHelpers::SerializerClassHelper
    end
  end
end
