# frozen_string_literal: true

class Serega
  #
  # Constructs map of attributes that should be serialized.
  # We will traverse this map to construct serialized response.
  #
  class SeregaMap
    #
    # SeregaMap class methods
    #
    module ClassMethods
      #
      # Constructs map of attributes that should be serialized.
      #
      # @param opts Serialization parameters
      # @option opts [Hash] :only The only attributes to serialize
      # @option opts [Hash] :except Attributes to hide
      # @option opts [Hash] :with Attributes (usually hidden) to serialize additionally
      #
      # @return [Array<Serega::SeregaMapPoint>] map
      #
      def call(opts)
        max_cache_size = serializer_class.config.max_cached_map_per_serializer_count
        return map_for(opts) if max_cache_size.zero?

        cached_map_for(opts, max_cache_size)
      end

      private

      def map_for(opts)
        construct_map(serializer_class, **modifiers(opts))
      end

      def cached_map_for(opts, max_cache_size)
        @cache ||= {}
        cache_key = opts.to_s
        map = @cache[cache_key] ||= map_for(opts)
        @cache.shift if @cache.length > max_cache_size
        map
      end

      def modifiers(opts)
        {
          only: opts[:only] || FROZEN_EMPTY_HASH,
          except: opts[:except] || FROZEN_EMPTY_HASH,
          with: opts[:with] || FROZEN_EMPTY_HASH
        }
      end

      def construct_map(serializer_class, only:, except:, with:)
        serializer_class.attributes.each_with_object([]) do |(name, attribute), map|
          next unless attribute.visible?(only: only, except: except, with: with)

          nested_points =
            if attribute.relation?
              construct_map(
                attribute.serializer,
                only: only[name] || FROZEN_EMPTY_HASH,
                with: with[name] || FROZEN_EMPTY_HASH,
                except: except[name] || FROZEN_EMPTY_HASH
              )
            end

          map << serializer_class::SeregaMapPoint.new(attribute, nested_points)
        end
      end
    end

    extend ClassMethods
    extend Serega::SeregaHelpers::SerializerClassHelper
  end
end
