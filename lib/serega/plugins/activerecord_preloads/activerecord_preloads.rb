# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin :activerecord_preloads
    # (depends on :preloads plugin, that must be loaded first)
    #
    # Automatically preloads associations to serialized objects
    #
    # It takes all defined preloads from serialized attributes (including attributes from serialized relations),
    # merges them into single associations hash and then uses ActiveRecord::Associations::Preloader
    # to preload all associations.
    #
    # @example
    #   class AppSerializer < Serega
    #     plugin :preloads,
    #       auto_preload_attributes_with_delegate: true,
    #       auto_preload_attributes_with_serializer: true,
    #       auto_hide_attributes_with_preload: true
    #
    #     plugin :activerecord_preloads
    #   end
    #
    #   class UserSerializer < AppSerializer
    #     # no preloads
    #     attribute :username
    #
    #     # preloads `:user_stats` as auto_preload_attributes_with_delegate option is true
    #     attribute :comments_count, delegate: { to: :user_stats }
    #
    #     # preloads `:albums` as auto_preload_attributes_with_serializer option is true
    #     attribute :albums, serializer: AlbumSerializer, hide: false
    #   end
    #
    #   class AlbumSerializer < AppSerializer
    #     # no preloads
    #     attribute :title
    #
    #     # preloads :downloads_count as manually specified
    #     attribute :downloads_count, preload: :downloads, value: proc { |album| album.downloads.count }
    #   end
    #
    #   UserSerializer.to_h(user) # => preloads {users_stats: {}, albums: { downloads: {} }}
    #
    module ActiverecordPreloads
      #
      # @return [Symbol] Plugin name
      #
      def self.plugin_name
        :activerecord_preloads
      end

      # Checks requirements to load plugin
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] plugin options
      #
      # @return [void]
      #
      def self.before_load_plugin(serializer_class, **opts)
        opts.each_key do |key|
          raise SeregaError, "Plugin #{plugin_name.inspect} does not accept the #{key.inspect} option. No options are allowed"
        end

        unless serializer_class.plugin_used?(:preloads)
          raise SeregaError, "Plugin #{plugin_name.inspect} must be loaded after the :preloads plugin. Please load the :preloads plugin first"
        end

        if serializer_class.plugin_used?(:batch)
          raise SeregaError, "Plugin #{plugin_name.inspect} must be loaded before the :batch plugin"
        end
      end

      #
      # Applies plugin code to specific serializer
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] Plugin options
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **_opts)
        require_relative "lib/preloader"

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
