# frozen_string_literal: true

class Serega
  module SeregaPlugins
    #
    # Plugin :depth_limit
    #
    # Helps to secure from malicious queries that require to serialize too much
    # or from accidental serializing of objects with cyclic relations.
    #
    # Depth limit is checked when constructing a serialization plan, that is when
    # `#new` method is called, ex: `SomeSerializer.new(with: params[:with])`.
    # It can be useful to instantiate serializer before any other business logic
    # to get possible errors earlier.
    #
    # Any class-level serialization methods also check depth limit as they also instantiate serializer.
    #
    # When depth limit is exceeded `Serega::DepthLimitError` is raised.
    # Depth limit error details can be found in additional `Serega::DepthLimitError#details` method
    #
    # Limit can be checked or changed with next config options:
    #
    #   - config.depth_limit.limit
    #   - config.depth_limit.limit=
    #
    # There are no default limit, but it should be set when enabling plugin.
    #
    # @example
    #
    #   class AppSerializer < Serega
    #     plugin :depth_limit, limit: 10 # set limit for all child classes
    #   end
    #
    #   class UserSerializer < AppSerializer
    #     config.depth_limit.limit = 5 # overrides limit for UserSerializer
    #   end
    #
    module DepthLimit
      # @return [Symbol] Plugin name
      def self.plugin_name
        :depth_limit
      end

      # Checks requirements
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] Plugin options
      #
      # @return [void]
      #
      def self.before_load_plugin(serializer_class, **opts)
        allowed_keys = %i[limit]
        opts.each_key do |key|
          next if allowed_keys.include?(key)

          raise SeregaError,
            "Plugin #{plugin_name.inspect} does not accept the #{key.inspect} option. Allowed options:\n" \
            "  - :limit [Integer] - Maximum serialization depth."
        end
      end

      #
      # Applies plugin code to specific serializer
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param _opts [Hash] Plugin options
      #
      # @return [void]
      #
      def self.load_plugin(serializer_class, **_opts)
        serializer_class::SeregaPlan.include(PlanInstanceMethods)
        serializer_class::SeregaConfig.include(ConfigInstanceMethods)
      end

      #
      # Adds config options and runs other callbacks after plugin was loaded
      #
      # @param serializer_class [Class<Serega>] Current serializer class
      # @param opts [Hash] Plugin options
      #
      # @return [void]
      #
      def self.after_load_plugin(serializer_class, **opts)
        config = serializer_class.config
        limit = opts.fetch(:limit) { raise SeregaError, "Please provide :limit option. Example: `plugin :depth_limit, limit: 10`" }
        config.opts[:depth_limit] = {}
        config.depth_limit.limit = limit
      end

      # DepthLimit config object
      class DepthLimitConfig
        attr_reader :opts

        #
        # Initializes DepthLimitConfig object
        #
        # @param opts [Hash] depth_limit plugin options
        #
        # @return [SeregaPlugins::DepthLimit::DepthLimitConfig] DepthLimitConfig object
        #
        def initialize(opts)
          @opts = opts
        end

        # @return [Integer] defined depth limit
        def limit
          opts.fetch(:limit)
        end

        #
        # Set depth limit
        #
        # @param value [Integer] depth limit
        #
        # @return [Integer] depth limit
        def limit=(value)
          raise SeregaError, "Depth limit must be an Integer" unless value.is_a?(Integer)

          opts[:limit] = value
        end
      end

      #
      # Serega::SeregaConfig additional/patched class methods
      #
      # @see Serega::SeregaConfig
      #
      module ConfigInstanceMethods
        # @return [Serega::SeregaPlugins::DepthLimit::DepthLimitConfig] current depth_limit config
        def depth_limit
          @depth_limit ||= DepthLimitConfig.new(opts.fetch(:depth_limit))
        end
      end

      #
      # SeregaPlan additional/patched instance methods
      #
      # @see SeregaPlan
      #
      module PlanInstanceMethods
        #
        # Initializes serialization plan
        # Overrides original method (adds depth_limit validation)
        #
        def initialize(parent_plan_point, *)
          check_depth_limit_exceeded(parent_plan_point)
          super
        end

        private

        def check_depth_limit_exceeded(current_point)
          plan = self
          depth_level = 1
          point = current_point

          while point
            depth_level += 1
            plan = point.plan
            point = plan.parent_plan_point
          end

          root_serializer = plan.class.serializer_class
          root_depth_limit = root_serializer.config.depth_limit.limit

          if depth_level > root_depth_limit
            fields_chain = [current_point.name]
            fields_chain << current_point.name while (current_point = current_point.plan.parent_plan_point)
            details = "#{root_serializer} (depth limit: #{root_depth_limit}) -> #{fields_chain.reverse!.join(" -> ")}"
            raise DepthLimitError.new("Depth limit was exceeded", details)
          end
        end
      end
    end

    register_plugin(DepthLimit.plugin_name, DepthLimit)
  end

  #
  # Special error for depth_limit plugin
  #
  class DepthLimitError < SeregaError
    #
    # Details of why depth limit error happens.
    #
    # @return [String] error details
    #
    attr_reader :details

    #
    # Initializes new error
    #
    # @param message [String] Error message
    # @param details [String] Error additional details
    #
    # @return [DepthLimitError] error instance
    #
    def initialize(message, details = nil)
      super(message)
      @details = details
    end
  end
end
