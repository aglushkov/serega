# frozen_string_literal: true

class Serega
  module SeregaPlugins
    module ActiverecordPreloads
      # Handles preloads for different types of initial records
      class Preloader
        class << self
          # Preloads associations to records
          #
          # @param object [Object] record(s)
          # @param preloads [Hash] associations names
          #
          # @return [Object] provided object with preloaded associations
          #
          def preload(object, preloads)
            return object if object.nil? || (object.is_a?(Array) && object.empty?) || preloads.empty?

            preload_handler = handlers.find { |handler| handler.fit?(object) }
            raise SeregaError, "Can't preload #{preloads.inspect} to #{object.inspect}" unless preload_handler

            preload_handler.preload(object, preloads)
          end

          # @return [Array] Registered preload adapters for different types of initial records
          def handlers
            @handlers ||= [
              ActiverecordRelation,
              ActiverecordObject,
              ActiverecordArray,
              ActiverecordEnumerator
            ].freeze
          end
        end
      end

      # Associations loader for prepared records
      class Loader
        # :nocov: We can check only one version of activerecord

        # Preloads associations to records
        #
        # @param records [Array<ActiveRecord::Base>] records
        # @param associations [Hash] associations names
        #
        # @return [void]
        #
        def self.call(records, associations)
          if ActiveRecord::VERSION::MAJOR >= 7
            ActiveRecord::Associations::Preloader.new(records: records, associations: associations).call
          else
            ActiveRecord::Associations::Preloader.new.preload(records, associations)
          end
        end
        # :nocov:
      end

      # Preloader adapter for ActiveRecord object
      class ActiverecordObject
        class << self
          # Checks object is kind of ActiveRecord::Base
          # @param object [Object] object
          # @return [Boolean] whether object is kind of ActiveRecord::Base
          def fit?(object)
            object.is_a?(ActiveRecord::Base)
          end

          # Preloads associations to ActiveRecord::Base object
          # @param object [ActiveRecord::Base] object
          # @return [Object] provided object with preloaded associations
          def preload(object, preloads)
            Loader.call([object], preloads)
            object
          end
        end
      end

      # Preloader adapter for ActiveRecord::Relation
      class ActiverecordRelation
        class << self
          # Checks object is kind of ActiveRecord::Relation
          # @param objects [Object] objects
          # @return [Boolean] whether object is kind of ActiveRecord::Relation
          def fit?(objects)
            objects.is_a?(ActiveRecord::Relation)
          end

          # Preloads associations to ActiveRecord::Relation
          # @param object [ActiveRecord::Relation] object
          # @return [ActiveRecord::Relation] provided relation with preloaded associations
          def preload(objects, preloads)
            objects.load
            Loader.call(objects.to_a, preloads)
            objects
          end
        end
      end

      # Preloader adapter for Array of ActiveRecord objects
      class ActiverecordArray
        class << self
          # Checks object is an array of ActiveRecord::Base objects
          # @param objects [Object] objects
          # @return [Boolean] whether object is Array with ActiveRecord objects (and all objects have same class)
          def fit?(objects)
            objects.is_a?(Array) &&
              ActiverecordObject.fit?(objects.first) &&
              same_kind?(objects)
          end

          # Preloads associations to Array with ActiveRecord::Base objects
          # @param object [Array<ActiveRecord::Base>] object
          # @return [Array<ActiveRecord::Base>] provided objects with preloaded associations
          def preload(objects, preloads)
            Loader.call(objects, preloads)
            objects
          end

          private

          def same_kind?(objects)
            first_object_class = objects.first.class
            objects.all? { |object| object.instance_of?(first_object_class) }
          end
        end
      end

      # Preloader adapter for Enumerator with ActiveRecord objects
      class ActiverecordEnumerator
        class << self
          # Checks object is an Enumerator with each value is a ActiveRecord::Base object
          # @param objects [Object] objects
          # @return [Boolean] whether object is an Enumerator with each value is a ActiveRecord::Base object
          def fit?(objects)
            objects.is_a?(Enumerator) &&
              ActiverecordArray.fit?(objects.to_a)
          end

          # Preloads associations to Enumerator with ActiveRecord::Base objects
          # @param object [Enumerator<ActiveRecord::Base>] object
          # @return [Enumerator<ActiveRecord::Base>] provided objects with preloaded associations
          def preload(objects, preloads)
            ActiverecordArray.preload(objects.to_a, preloads)
            objects
          end
        end
      end
    end
  end
end
