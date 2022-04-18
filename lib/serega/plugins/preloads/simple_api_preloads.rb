# frozen_string_literal: true

require_relative "./lib/preloads"

class Serega
  module Plugins
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
        serializer_class.extend(ClassMethods)
        serializer_class.include(InstanceMethods)
      end

      # Adds .preloads class method
      module ClassMethods
        #
        # Shows relations that can be preloaded to omit N+1
        #
        # @param context [Hash] Serialization context
        #
        # @return [Hash]
        #
        def preloads(context = {})
          new(context).preloads
        end
      end

      # Adds #preloads instance method
      module InstanceMethods
        # @return [Hash] relations that can be preloaded to omit N+1
        def preloads
          @preloads ||= Preloads.call(self)
        end
      end
    end

    register_plugin(SimpleApiPreloads.plugin_name, SimpleApiPreloads)
  end
end
