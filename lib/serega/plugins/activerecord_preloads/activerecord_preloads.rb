# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin that checks used plugins and loads correct Preloader for selected response type
    # @see Serega::SeregaPlugins::JsonApiActiverecordPreloader
    # @see Serega::SeregaPlugins::SimpleApiActiverecordPreloader
    #
    module ActiverecordPreloads
      # @return [Symbol] plugin name
      def self.plugin_name
        :activerecord_preloads
      end

      def self.before_load_plugin(serializer_class, **opts)
        if serializer_class.plugin_used?(:batch)
          raise SeregaError, "Plugin `activerecord_preloads` must be loaded before `batch`"
        end

        serializer_class.plugin(:preloads, **opts) unless serializer_class.plugin_used?(:preloads)
      end

      #
      # Loads plugin code and additional plugins
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] loaded plugins opts
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **opts)
        require_relative "./lib/preloader"

        serializer_class.include(InstanceMethods)
      end

      # Overrides Serega classes instance methods
      module InstanceMethods
        #
        # Override original #to_h method
        # @see Serega#to_h
        #
        def to_h(object, *)
          object = add_preloads(object)
          super
        end

        private

        def add_preloads(obj)
          return obj if obj.nil? || (obj.is_a?(Array) && obj.empty?)

          # preloads() method comes from :preloads plugin
          preloads = preloads()
          return obj if preloads.empty?

          Preloader.preload(obj, preloads)
        end
      end
    end

    register_plugin(ActiverecordPreloads.plugin_name, ActiverecordPreloads)
  end
end
