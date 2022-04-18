# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Root
      # @return [Symbol] Default response root key
      ROOT_DEFAULT = :data

      def self.plugin_name
        :root
      end

      def self.load_plugin(serializer_class, **_opts)
        serializer_class.extend(SeregaClassMethods)
        serializer_class::SeregaConvert.include(ConvertInstanceMethods)
      end

      def self.after_load_plugin(serializer_class, **opts)
        serializer_class.root(root: opts[:root] || ROOT_DEFAULT, root_one: opts[:root_one], root_many: opts[:root_many])
      end

      module SeregaClassMethods
        #
        # Configures response root key
        #
        # @param root [String, Symbol] Specifies common root when serializing one or multiple objects
        # @param root_one [String, Symbol] Specifies root when serializing one object
        # @param root_many [String, Symbol] Specifies root when serializing multiple objects
        #
        # @return [Hash] Configured root names
        #
        def root(root: nil, root_one: nil, root_many: nil)
          root_one ||= root
          root_many ||= root

          config[:root_one] = root_one ? root_one.to_sym : nil
          config[:root_many] = root_many ? root_many.to_sym : nil

          {root_one: root_one, root_many: root_many}
        end
      end

      module ConvertInstanceMethods
        def to_h
          hash = super
          hash = {root => hash} if root
          hash
        end

        private

        def root
          return @root if defined?(@root)

          config = serializer_class.config
          root = many? ? config[:root_many] : config[:root_one]
          @root = root
        end
      end
    end

    register_plugin(Root.plugin_name, Root)
  end
end
