# frozen_string_literal: true

class Serega
  #
  # Utilities
  #
  module SeregaUtils
    #
    # Utility to count regular parameters of callable object
    #
    class ParamsCount
      NO_NAMED_REST_PARAM = [:rest].freeze
      private_constant :NO_NAMED_REST_PARAM

      class << self
        #
        # Count parameters for callable object
        #
        # @param object [#call] callable object
        #
        # @return [Integer] count of regular parameters
        #
        def call(object, max_count:)
          # Procs (but not lambdas) can accept all provided parameters
          return max_count if object.is_a?(Proc) && !object.lambda?

          parameters = object.is_a?(Proc) ? object.parameters : object.method(:call).parameters
          count = 0

          # If all we have is no-name *rest parameters, then we assume we need to provide
          # 1 argument. It is now always correct, but in serialization context it's most common that
          # only one argument is needed.
          return 1 if parameters[0] == NO_NAMED_REST_PARAM

          parameters.each do |parameter|
            next if parameter == NO_NAMED_REST_PARAM # Workaround for procs like :odd?.to_proc
            param_type = parameter[0]

            case param_type
            when :req then count += 1
            when :opt then count += 1 if count < max_count
            when :rest then count += max_count - count if max_count > count
            end # else :opt, :keyreq, :key, :keyrest, :block - do nothing
          end

          count
        end
      end
    end
  end
end
