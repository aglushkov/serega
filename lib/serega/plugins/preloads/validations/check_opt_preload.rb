# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module Preloads
      class CheckOptPreload
        class << self
          def call(opts)
            return unless opts.key?(:preload)

            raise SeregaError, "Option :preload can not be used together with option :const" if opts.key?(:const)
          end
        end
      end
    end
  end
end
