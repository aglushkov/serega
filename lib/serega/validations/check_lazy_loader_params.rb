# frozen_string_literal: true

class Serega
  module SeregaValidations
    #
    # Lazy loader parameters validators
    #
    class CheckLazyLoaderParams
      #
      # Validations for Serializer.lazy_loader params instance methods
      #
      module InstanceMethods
        # @return [Symbol] validated lazy_loader name
        attr_reader :name

        # @return [nil, #call] validated lazy_loader value or block
        attr_reader :block

        def initialize(name, lazy_loader)
          @name = name
          @lazy_loader = lazy_loader
        end

      class << self
        #
        # Checks lazy loader value parameter (or block provided instead of value).
        # @api private
        #
        # @param lazy_loader [Proc] LazyLoader callable value
        #
        # @raise [SeregaError] SeregaError that lazy loader has invalid arguments
        #
        # @return [void]
        #
        def call(name, lazy_loader)
          check_name(name)
          check_loader(lazy_loader)
        end

        private

        def check_name(name)
          raise SeregaError, name_type_error if !name.is_a?(Symbol) && !name.is_a?(String)
        end

        def check_loader(lazy_loader)
          check_lazy_loader_type(lazy_loader)
          check_lazy_loader_args(lazy_loader)
        end

        def check_lazy_loader_type(lazy_loader)
          raise SeregaError, type_error if !lazy_loader.is_a?(Proc) && !lazy_loader.respond_to?(:call)
        end

        def check_lazy_loader_args(lazy_loader)
          signature = SeregaUtils::MethodSignature.call(lazy_loader, pos_limit: 1, keyword_args: [:ctx])

          raise SeregaError, arguments_error unless %w[1 1_ctx].include?(signature)
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
    end
  end
end
