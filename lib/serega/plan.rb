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
      # @option opts [Hash] :with Attributes (usually marked `hide: true`) to serialize additionally
      #
      # @return [SeregaPlan] Serialization plan
      #
      def call(opts)
        max_cache_size = serializer_class.config.max_cached_plans_per_serializer_count
        return plan_for(opts) if max_cache_size.zero?

        cached_plan_for(opts, max_cache_size)
      end

      private

      def plan_for(opts)
        new(**modifiers(opts))
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

    module InstanceMethods
      # Parent plan point, if exists
      # @return [SeregaPlanPoint, nil]
      attr_reader :parent_plan_point

      # Serialization points
      # @return [Array<SeregaPlanPoint>] points to serialize
      attr_reader :points

      #
      # Instantiate new serialization plan.
      #
      # @param opts Serialization parameters
      # @option opts [Hash] :only The only attributes to serialize
      # @option opts [Hash] :except Attributes to hide
      # @option opts [Hash] :with Attributes (usually marked hide: true`) to serialize additionally
      # @option opts [Hash] :with Attributes (usually marked hide: true`) to serialize additionally
      #
      # @return [SeregaPlan] Serialization plan
      #
      def initialize(only:, except:, with:, parent_plan_point: nil)
        @parent_plan_point = parent_plan_point
        @points = attributes_points(only: only, except: except, with: with)
      end

      def serializer_class
        self.class.serializer_class
      end

      private

      def attributes_points(only:, except:, with:)
        points = []

        serializer_class.attributes.each_value do |attribute|
          next unless attribute.visible?(only: only, except: except, with: with)

          child_fields =
            if attribute.relation?
              name = attribute.name
              {only: only[name], with: with[name], except: except[name]}
            end

          points << serializer_class::SeregaPlanPoint.new(attribute, self, child_fields)
        end

        points.freeze
      end
    end

    extend ClassMethods
    include InstanceMethods
    extend SeregaHelpers::SerializerClassHelper
  end
end
