# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Metadata
      class MetaAttribute
        #
        # Validator for meta_attribute :value option
        #
        class CheckOptValue
          class << self
            #
            # Checks attribute :value option
            #
            # @param opts [Hash] Attribute options
            #
            # @raise [SeregaError] SeregaError that option has invalid value
            #
            # @return [void]
            #
            def call(opts, block = nil)
              return unless opts.key?(:value)

              check_usage_with_other_params(opts, block)

              check_value(opts[:value])
            end

            private

            def check_usage_with_other_params(opts, block)
              raise SeregaError, "Option :value can not be used together with option :const" if opts.key?(:const)
              raise SeregaError, "Option :value can not be used together with block" if block
            end

            def check_value(value)
              check_value_type(value)

              SeregaValidations::Utils::CheckExtraKeywordArg.call(value, ":value option")
              params_count = SeregaUtils::ParamsCount.call(value, max_count: 2)

              raise SeregaError, params_count_error if params_count > 2
            end

            def check_value_type(value)
              raise SeregaError, type_error if !value.is_a?(Proc) && !value.respond_to?(:call)
            end

            def type_error
              "Option :value value must be a Proc or respond to #call"
            end

            def params_count_error
              "Option :value value can have maximum 2 parameters (object(s), context)"
            end
          end
        end
      end
    end
  end
end
