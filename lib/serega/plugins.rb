# frozen_string_literal: true

class Serega
  # Module in which all Serega plugins should be stored
  module Plugins
    @plugins = {}

    class << self
      #
      # Registers given plugin to be able to load it using symbol name.
      #
      # @example Register plugin
      #   Serega::Plugins.register_plugin(:plugin_name, PluginModule)
      def register_plugin(name, mod)
        @plugins[name] = mod
      end

      #
      # Loads plugin code and returns plugin core module.
      #
      # @param name [Symbol, Module] plugin name or plugin itself
      #
      # @raise [Error] Raises Error when plugin was not found
      #
      # @example Find plugin when providing name
      #   Serega::Plugins.find_plugin(:presenter) # => Serega::Plugins::Presenter
      #
      # @example Find plugin when providing plugin itself
      #   Serega::Plugins.find_plugin(Presenter) # => Presenter
      #
      # @return [Class<Module>] Plugin core module
      #
      def find_plugin(name)
        return name if name.is_a?(Module)
        return @plugins[name] if @plugins.key?(name)

        require_plugin(name)

        @plugins[name] || raise(Error, "Plugin '#{name}' did not register itself correctly")
      end

      private

      def require_plugin(name)
        require "serega/plugins/#{name}/#{name}"
      rescue LoadError
        raise Error, "Plugin '#{name}' does not exist"
      end
    end
  end
end
