class Serega
  class SeregaMap
    module ClassMethods
      def call(only:, except:, with:)
        params = {only: only, except: except, with: with}
        @cache ||= {}
        cache_key = params.to_s

        (@cache[cache_key] ||= construct_map(serializer_class, **params)).tap do
          @cache.shift if @cache.length >= serializer_class.config[:max_cached_map_per_serializer_count]
        end
      end

      private

      def construct_map(serializer_class, only:, except:, with:)
        serializer_class.attributes.each_with_object([]) do |attribute, map|
          next unless attribute.visible?(only: only, except: except, with: with)

          nested_map =
            if attribute.relation?
              name = attribute.name
              construct_map(attribute.serializer, only: only[name] || {}, with: with[name] || {}, except: except[name] || {})
            else
              FROZEN_EMPTY_ARRAY
            end

          map << [attribute, nested_map]
        end
      end
    end

    extend ClassMethods
    extend Serega::SeregaHelpers::SeregaSerializerClassHelper
  end
end
