# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Metadata
      class SeregaMetaAttribute
        class CheckPath
          module ClassMethods
            FORMAT_ONE_CHAR = /\A[a-zA-Z0-9]\z/
            FORMAT_MANY_CHARS = /\A[a-zA-Z0-9][a-zA-Z0-9_-]*?[a-zA-Z0-9]\z/ # allow '-' and '_' in the middle

            private_constant :FORMAT_ONE_CHAR, :FORMAT_MANY_CHARS

            #
            # Checks allowed characters in specified metadata path parts.
            # Globally allowed characters: "a-z", "A-Z", "0-9".
            # Minus and low line "-", "_" also allowed except as the first or last character.
            #
            # @param path [Array<String, Symbol>] Metadata attribute path names
            #
            # @raise [SeregaError] when metadata attribute name has invalid format
            # @return [void]
            #
            def call(path)
              path.each { |attr_name| check_name(attr_name) }
            end

            private

            def check_name(name)
              name = name.to_s

              valid =
                case name.size
                when 0 then false
                when 1 then name.match?(FORMAT_ONE_CHAR)
                else name.match?(FORMAT_MANY_CHARS)
                end

              return if valid

              raise SeregaError, message(name)
            end

            def message(name)
              %(Invalid metadata path #{name.inspect}, globally allowed characters: "a-z", "A-Z", "0-9". Minus and low line "-", "_" also allowed except as the first or last character)
            end
          end

          extend ClassMethods
        end
      end
    end
  end
end
