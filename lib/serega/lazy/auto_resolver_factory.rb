# frozen_string_literal: true

class Serega
  module SeregaLazy
    #
    # Factory generates callable object that should be able to take
    # lazy loaded results, current object, and find attribute value for this
    # object
    #
    class AutoResolverFactory
      #
      # Generates callable block to find attribute value when attribute with :lazy
      # option has no block or manual :value option.
      #
      # It handles this cases:
      # - `attribute :foo, lazy: true`
      # - `attribute :foo, lazy: FooLoader`
      # - `attribute :foo, lazy: { use: FooLoader, id: foo_id }`
      # - `attribute :foo, lazy: { use: :foo_loader, id: foo_id }`
      #
      # In other cases we should never call tis method here.
      #
      def self.get(serializer_class, attribute_name, lazy_opt)
        if lazy_opt == true                        # ex: `lazy: true`
          loader_name = attribute_name
          loader_id_method = :id
        elsif lazy_opt.respond_to?(:call)          # ex: `lazy: FooLoader`
          serializer_class.lazy_loader(attribute_name, lazy_opt)
          loader_name = attribute_name
          loader_id_method = :id
        else
          use = lazy_opt[:use]
          loader_id_method = lazy_opt[:id] || :id

          if use.respond_to?(:call)                 # ex: `lazy: { use: FooLoader }`
            loader_name = attribute_name
            serializer_class.lazy_loader(loader_name, use)
          else                                      # ex: `lazy: { use: :foo }`
            loader_name = use
          end
        end

        AutoResolver.new(loader_name, loader_id_method)
      end
    end
  end
end
