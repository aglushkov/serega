# frozen_string_literal: true

class Serega
  #
  # Utilities
  #
  module SeregaUtils
    #
    # Utility to make method arguments signature
    #
    class MethodSignature
      SYMBOL_TO_PROC_SIGNATURE_RUBY2 = [[:rest]]
      SYMBOL_TO_PROC_SIGNATURE_RUBY3 = [[:req], [:rest]]
      private_constant :SYMBOL_TO_PROC_SIGNATURE_RUBY2
      private_constant :SYMBOL_TO_PROC_SIGNATURE_RUBY3

      class << self
        #
        # Generates method arguments signature
        #
        # @param callable [#call] callable object
        # @param pos_limit [Integer] Max count of positional parameters
        # @param keyword_args [Array<Symbol>] List of accepted keyword argument names
        #
        # @return [String] Method signature which consist of number of positional parameters and
        #    keyword parameter names joined with undescrore.
        #
        def call(callable, pos_limit:, keyword_args: [])
          params = callable.is_a?(Proc) ? callable.parameters : callable.method(:call).parameters

          # Procs (but not lambdas) can accept all provided parameters
          return full_signature(pos_limit, keyword_args) if params.empty? && callable.is_a?(Proc) && !callable.lambda?

          # Return signle positional argument for Symbol#to_proc
          return "1" if (params == SYMBOL_TO_PROC_SIGNATURE_RUBY2) || (params == SYMBOL_TO_PROC_SIGNATURE_RUBY3)

          keyword_args = keyword_args.dup

          # Temporar signature object is an array where first item is a counter
          # of positional parameters and next arguments are the names of
          # keyword arguments. We will join this signature to a string finally.
          signature = [0]

          params.each do |type, name|
            case type
            when :req
              signature[0] += 1
              pos_limit -= 1
            when :opt
              next if pos_limit <= 0

              signature[0] += 1
              pos_limit -= 1
            when :rest
              next if pos_limit <= 0

              signature[0] += pos_limit
              pos_limit = 0
            when :keyreq
              signature << name
              keyword_args.delete(name)
            when :key
              next unless keyword_args.include?(name)

              signature << name
              keyword_args.delete(name)
            when :keyrest
              signature.concat(keyword_args)
              keyword_args.clear
            end
          end

          signature.join("_")
        end

        private

        def full_signature(pos_limit, keyword_args)
          signature = [pos_limit]
          signature.concat(keyword_args)
          signature.join("_")
        end
      end
    end
  end
end
