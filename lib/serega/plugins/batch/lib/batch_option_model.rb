# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Batch
      #
      # Combines options and methods needed to load batch for specific attribute
      #
      class BatchOptionModel
        attr_reader :attribute, :opts, :loaders, :many

        #
        # Initializes BatchOptionModel
        #
        # @param plan_point [Serega::SeregaPlanPoint] Map point for attribute with :batch option
        # @param loaders [Array] Array of all loaders defined in serialize class
        # @param many [Boolean] Option :many, defined on attribute
        #
        # @return [void]
        def initialize(attribute)
          @attribute = attribute
          @opts = attribute.batch
          @loaders = attribute.class.serializer_class.config.batch_loaders
          @many = attribute.many
        end

        # Returns proc that will be used to batch load registered keys values
        # @return [#call] batch loader
        def loader
          @batch_loader ||= begin
            loader = opts[:loader]
            loader = loaders.fetch(loader) if loader.is_a?(Symbol)
            loader
          end
        end

        # Returns proc that will be used to find batch_key for current attribute.
        # @return [Object] key (uid) of batch loaded object
        def key
          @batch_key ||= begin
            key = opts[:key]

            if key.is_a?(Symbol)
              proc do |object|
                handle_no_method_error { object.public_send(key) }
              end
            else
              key
            end
          end
        end

        # Returns default value to use if batch loader does not return value for some key
        # @return [Object] default value for missing key
        def default_value
          if opts.key?(:default)
            opts[:default]
          elsif many
            FROZEN_EMPTY_ARRAY
          end
        end

        private

        def handle_no_method_error
          yield
        rescue NoMethodError => error
          raise error, "NoMethodError when serializing '#{attribute.name}' attribute in #{attribute.class.serializer_class}\n\n#{error.message}", error.backtrace
        end
      end
    end
  end
end
