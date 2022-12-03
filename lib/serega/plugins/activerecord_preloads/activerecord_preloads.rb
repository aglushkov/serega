# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin that automatically preloads relations to serialized objects
    #
    module ActiverecordPreloads
      # @return [Symbol] Plugin name
      def self.plugin_name
        :activerecord_preloads
      end

      # Checks requirements and loads additional plugins
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.before_load_plugin(serializer_class, **opts)
        if serializer_class.plugin_used?(:batch)
          raise SeregaError, "Plugin `activerecord_preloads` must be loaded before `batch`"
        end

        serializer_class.plugin(:preloads, **opts) unless serializer_class.plugin_used?(:preloads)
      end

      #
      # Applies plugin code to specific serializer
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] Loaded plugins options
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **_opts)
        require_relative "./lib/preloader"

        serializer_class.include(InstanceMethods)
      end

      #
      # Overrides Serega class instance methods
      #
      module InstanceMethods
        private

        #
        # Override original #serialize method
        # Preloads associations to object before serialization
        #
        def serialize(object, _opts)
          object = add_preloads(object)
          super
        end

        def add_preloads(obj)
          return obj if obj.nil? || (obj.is_a?(Array) && obj.empty?)

          preloads = preloads() # `preloads()` method comes from :preloads plugin
          return obj if preloads.empty?

          Preloader.preload(obj, preloads)
        end
      end
    end

    register_plugin(ActiverecordPreloads.plugin_name, ActiverecordPreloads)
  end
end
