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
        serializer_class.extend(ClassMethods)
        serializer_class::Convert.include(ConvertInstanceMethods)
      end

      def self.after_load_plugin(serializer_class, **opts)
        serializer_class.root(opts[:root] || ROOT_DEFAULT, one: opts[:root_one], many: opts[:root_many])
        serializer_class.config[:serialize_keys] << :root
      end

      module ClassMethods
        #
        # Configures response root key
        #
        # @param root [String, Symbol] Specifies common root when serializing one or multiple objects
        # @param root_one [String, Symbol] Specifies root when serializing one object
        # @param root_many [String, Symbol] Specifies root when serializing multiple objects
        #
        # @return [Hash] Configured root names
        #
        def root(root = nil, one: nil, many: nil)
          one ||= root
          many ||= root

          one = one.to_sym if one
          many = many.to_sym if many

          config[:root] = {one: one, many: many}
        end
      end

      module ConvertInstanceMethods
        def to_h
          hash = super
          root = build_root(opts)
          hash = {root => hash} if root
          hash
        end

        private

        def build_root(opts)
          return opts[:root] if opts.key?(:root)

          root_config = self.class.serializer_class.config[:root]
          many? ? root_config[:many] : root_config[:one]
        end
      end
    end

    register_plugin(Root.plugin_name, Root)
  end
end
