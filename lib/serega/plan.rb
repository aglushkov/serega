# frozen_string_literal: true

class Serega
  #
  # Constructs plan - list of serialized attributes.
  # We will traverse this plan to construct serialized response.
  #
  class SeregaPlan
    #
    # SeregaPlan class methods
    #
    module ClassMethods
      #
      # Constructs plan of attributes that should be serialized.
      #
      # @param opts Serialization parameters
      # @option opts [Hash] :only The only attributes to serialize
      # @option opts [Hash] :except Attributes to hide
      # @option opts [Hash] :with Attributes (usually hidden) to serialize additionally
      #
      # @return [Array<Serega::SeregaPlanPoint>] plan
      #
      def call(opts)
        max_cache_size = serializer_class.config.max_cached_plans_per_serializer_count
        return plan_for(opts) if max_cache_size.zero?

        cached_plan_for(opts, max_cache_size)
      end

      private

      def plan_for(opts)
        construct_plan(serializer_class, **modifiers(opts))
      end

      def cached_plan_for(opts, max_cache_size)
        @cache ||= {}
        cache_key = construct_cache_key(opts)

        plan = @cache[cache_key] ||= plan_for(opts)
        @cache.shift if @cache.length > max_cache_size
        plan
      end

      def modifiers(opts)
        {
          only: opts[:only] || FROZEN_EMPTY_HASH,
          except: opts[:except] || FROZEN_EMPTY_HASH,
          with: opts[:with] || FROZEN_EMPTY_HASH
        }
      end

      def construct_plan(serializer_class, only:, except:, with:)
        plan = []
        serializer_class.attributes.each do |name, attribute|
          next unless attribute.visible?(only: only, except: except, with: with)

          nested_points =
            if attribute.relation?
              construct_plan(
                attribute.serializer,
                only: only[name] || FROZEN_EMPTY_HASH,
                with: with[name] || FROZEN_EMPTY_HASH,
                except: except[name] || FROZEN_EMPTY_HASH
              )
            end

          plan << serializer_class::SeregaPlanPoint.new(attribute, nested_points)
        end
        plan
      end

      def construct_cache_key(opts, cache_key = nil)
        return nil if opts.empty?

        cache_key ||= +""

        opts.each do |key, nested_opts|
          cache_key.insert(-1, SeregaUtils::SymbolName.call(key))
          cache_key.insert(-1, "-")
          construct_cache_key(nested_opts, cache_key)
        end

        cache_key
      end
    end

    extend ClassMethods
    extend Serega::SeregaHelpers::SerializerClassHelper
  end
end
