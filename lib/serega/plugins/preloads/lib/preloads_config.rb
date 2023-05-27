# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      #
      # Config for `preloads` plugin
      #
      class PreloadsConfig
        # @return [Hash] preloads plugin options
        attr_reader :opts

        #
        # Initializes context_metadata config object
        #
        # @param opts [Hash] options
        #
        # @return [Serega::SeregaPlugins::Metadata::MetadataConfig]
        #
        def initialize(opts)
          @opts = opts
        end

        # @!method auto_preload_attributes_with_delegate
        #   @return [Boolean, nil] option value
        #
        # @!method auto_preload_attributes_with_delegate=(value)
        #   @param value [Boolean] New option value
        #   @return [Boolean] New option value
        #
        # @!method auto_preload_attributes_with_serializer
        #   @return [Boolean, nil] option value
        #
        # @!method auto_preload_attributes_with_serializer=(value)
        #   @param value [Boolean] New option value
        #   @return [Boolean] New option value
        #
        # @!method auto_hide_attributes_with_preload
        #   @return [Boolean, nil] option value
        #
        # @!method auto_hide_attributes_with_preload=(value)
        #   @param value [Boolean] New option value
        #   @return [Boolean] New option value
        #
        %i[
          auto_preload_attributes_with_delegate
          auto_preload_attributes_with_serializer
          auto_hide_attributes_with_preload
        ].each do |method_name|
          define_method(method_name) do
            opts.fetch(method_name)
          end

          define_method("#{method_name}=") do |value|
            raise SeregaError, "Must have boolean value, #{value.inspect} provided" if (value != true) && (value != false)
            opts[method_name] = value
          end
        end
      end
    end
  end
end
