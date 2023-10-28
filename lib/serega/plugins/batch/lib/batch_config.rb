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
        # @param block [Proc] Block that can accept 3 parameters - keys, context, plan_point
        #   and returns hash where ids are keys and values are batch loaded objects/
        #
        # @return [void]
        #
        def define(loader_name, callable = nil, &block)
          if (!callable && !block) || (callable && block)
            raise SeregaError, "Batch loader can be specified with one of arguments - callable value or &block"
          end

          callable ||= block
          SeregaValidations::Utils::CheckExtraKeywordArg.call(callable, "batch loader `#{loader_name}`")
          params_count = SeregaUtils::ParamsCount.call(callable, max_count: 3)

          if params_count > 3
            raise SeregaError, "Batch loader can have maximum 3 parameters (keys, context, plan)"
          end

          loaders[loader_name] = callable
        end

        # Shows defined loaders
        # @return [Hash] defined loaders
        def loaders
          opts[:loaders]
        end

        #
        # Finds previously defined batch loader by name
        #
        # @param loader_name [Symbol]
        #
        # @return [Proc] batch loader block
        def fetch_loader(loader_name)
          loaders[loader_name] || (raise SeregaError, "Batch loader with name `#{loader_name.inspect}` was not defined. Define example: config.batch.define(:#{loader_name}) { |keys| ... }")
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

        # Shows default key for :batch option
        # @return [Symbol, nil] default key for :batch option
        def default_key
          opts[:default_key]
        end

        # @param value [Symbol] New :default_key option value
        # @return [Boolean] New option value
        def default_key=(value)
          raise SeregaError, "Must be a Symbol, #{value.inspect} provided" unless value.is_a?(Symbol)
          opts[:default_key] = value
        end
      end
    end
  end
end
