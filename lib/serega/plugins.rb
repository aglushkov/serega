# frozen_string_literal: true

class Serega
  # Module in which all Serega plugins should be stored
  module SeregaPlugins
    @plugins = {}

    class << self
      #
      # Registers given plugin to be able to load it using symbol name.
      #
      # @example Register plugin
      #   Serega::SeregaPlugins.register_plugin(:plugin_name, PluginModule)
      def register_plugin(name, mod)
        @plugins[name] = mod
      end

      #
      # Loads plugin code and returns plugin core module.
      #
      # @param name [Symbol, Module] plugin name or plugin itself
      #
      # @raise [SeregaError] Raises SeregaError when plugin was not found
      #
      # @example Find plugin when providing name
      #   Serega::SeregaPlugins.find_plugin(:presenter) # => Serega::SeregaPlugins::Presenter
      #
      # @example Find plugin when providing plugin itself
      #   Serega::SeregaPlugins.find_plugin(Presenter) # => Presenter
      #
      # @return [Class<Module>] Plugin core module
      #
      def find_plugin(name)
        return name if name.is_a?(Module)
        return @plugins[name] if @plugins.key?(name)

        require_plugin(name)

        @plugins[name] || raise(SeregaError, "Plugin '#{name}' did not register itself correctly")
      end

      private

      def require_plugin(name)
        require "serega/plugins/#{name}/#{name}"
      rescue LoadError
        raise SeregaError, "Plugin '#{name}' does not exist"
      end
    end
  end
end
