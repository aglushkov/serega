# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Batch plugin config
      #
      class BatchConfig
        attr_reader :opts

        def initialize(opts)
          @opts = opts
        end

        #
        # Defines batch loader
        #
        # @param loader_name [Symbol] Batch loader name, that is used when defining attribute with batch loader.
        # @param block [Proc] Block that can accept 3 parameters - ids, context, plan_point
        #   and returns hash with ids as keys and values are batch loaded objects
        #
        # @return [void]
        #
        def define(loader_name, callable = nil, &block)
          if (!callable && !block) || (callable && block)
            raise SeregaError, "Batch loader can be specified with one of arguments - callable value or &block"
          end

          callable ||= block

          signature = SeregaUtils::MethodSignature.call(callable, pos_limit: 3, keyword_args: [])

          unless %w[0 1 2 3].include?(signature)
            raise SeregaError, "Batch loader can have maximum 3 parameters (ids, context, plan)"
          end

          loaders[loader_name] = callable
        end

        # Shows defined loaders
        # @return [Hash] defined loaders
        def loaders
          opts[:loaders]
        end

        # Shows option to auto hide attributes with :batch specified
        # @return [Boolean, nil] option value
        def auto_hide
          opts[:auto_hide]
        end

        # @param value [Boolean] New :auto_hide option value
        # @return [Boolean] New option value
        def auto_hide=(value)
          raise SeregaError, "Must have boolean value, #{value.inspect} provided" if (value != true) && (value != false)
          opts[:auto_hide] = value
        end

        # Shows method name or callable object needed to get object identifier for batch load
        # @return [Symbol, #call, nil] Default method name or callable object to get identifier
        def id_method
          opts[:id_method]
        end

        # Sets new identifier method name or callable value needed for batch loading
        #
        # @param value [Symbol, #call] New :id_method value
        # @return [Boolean] New option value
        def id_method=(value)
          CheckBatchOptIdMethod.call(value)
          opts[:id_method] = value
        end
      end
    end
  end
end
