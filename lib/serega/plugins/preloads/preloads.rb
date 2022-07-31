# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin adds `.preloads` method to find relations that must be preloaded
    #
    module Preloads
      # @return [Symbol] plugin name
      def self.plugin_name
        :preloads
      end

      #
      # Includes plugin modules to current serializer
      #
      # @param serializer_class [Class] current serializer class
      # @param _opts [Hash] plugin opts
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **_opts)
        serializer_class.include(InstanceMethods)
        serializer_class::SeregaAttribute.include(AttributeMethods)

        serializer_class::CheckAttributeParams.include(CheckAttributeParamsInstanceMethods)

        require_relative "./lib/enum_deep_freeze"
        require_relative "./lib/format_user_preloads"
        require_relative "./lib/main_preload_path"
        require_relative "./lib/preloads_constructor"
        require_relative "./validations/check_opt_preload_path"
      end

      def self.after_load_plugin(serializer_class, **opts)
        config = serializer_class.config
        config[:attribute_keys] += [:preload, :preload_path]
        config[:preloads] = {
          auto_preload_attributes_with_serializer: opts.fetch(:auto_preload_attributes_with_serializer, false),
          auto_hide_attributes_with_preload: opts.fetch(:auto_hide_attributes_with_preload, false)
        }
      end

      # Adds #preloads instance method
      module InstanceMethods
        # @return [Hash] relations that can be preloaded to omit N+1
        def preloads
          @preloads ||= PreloadsConstructor.call(map)
        end
      end

      # Adds #preloads and #preloads_path Attribute instance method
      module AttributeMethods
        def preloads
          return @preloads if defined?(@preloads)

          @preloads = get_preloads
        end

        def preloads_path
          return @preloads_path if defined?(@preloads_path)

          @preloads_path = get_preloads_path
        end

        def hide
          res = super
          return res unless res.nil?

          auto_hide_attribute_with_preloads? || nil
        end

        private

        def auto_hide_attribute_with_preloads?
          return @auto_hide_attribute_with_preloads if defined?(@auto_hide_attribute_with_preloads)

          auto = self.class.serializer_class.config[:preloads][:auto_hide_attributes_with_preload]
          @auto_hide_attribute_with_preloads = auto && !preloads.nil? && (preloads != false) && (preloads != {})
        end

        def get_preloads
          preloads_provided = opts.key?(:preload)
          preloads =
            if preloads_provided
              opts[:preload]
            elsif relation? && self.class.serializer_class.config[:preloads][:auto_preload_attributes_with_serializer]
              key
            end

          # Nil and empty hash differs as we can preload nested results to
          # empty hash, but we will skip nested preloading if nil or false provided
          return if preloads_provided && !preloads

          FormatUserPreloads.call(preloads)
        end

        def get_preloads_path
          path = Array(opts[:preload_path]).map!(&:to_sym)
          path = MainPreloadPath.call(preloads) if path.empty?
          EnumDeepFreeze.call(path)
        end
      end

      module CheckAttributeParamsInstanceMethods
        private

        def check_opts
          super
          CheckOptPreloadPath.call(opts)
        end
      end
    end

    register_plugin(Preloads.plugin_name, Preloads)
  end
end
