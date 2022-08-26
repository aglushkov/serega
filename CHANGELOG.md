## [Unreleased]

- Allow to provide formatters config when adding `formatters` plugin
  ```ruby
    plugin :formatters, formatters: {
      iso8601: ->(value) { time.iso8601.round(6) },
      on_off: ->(value) { value ? 'ON' : 'OFF' },
      money: ->(value) { value.round(2) }
    }
  ```

## [0.3.0] - 2022-08-10

- Use Oj JSON adapter by default if Oj is loaded. We use `mode: :compat` when   serializing objects. Config can still be overwritten:
  ```ruby
   config.to_json = proc { |data| Oj.dump(mode: :strict) }
   config.from_json = proc { |json| Oj.load(json) }
  ```

- We can now access config options through methods instead of hash keys
  ```ruby

      config.plugins # Shows enabled plugins
      config.initiate_keys # Shows allowed options keys when initiating serializer
      config.attribute_keys # Shows allowed options keys when adding new attribute
      config.serialize_keys # Shows allowed options keys when serializing object with #call, #to_h, #to_json, #as_json methods
      config.check_initiate_params # Shows value of check_initiate_params option. Default is true
      config.check_initiate_params=(bool_value) # Changes check_initiate_params option. When value is false - it skips invalid initiate options and values
      config.max_cached_map_per_serializer_count # Shows count of cached maps per serializer. Default is 0
      config.max_cached_map_per_serializer_count=(int_value) # Changes count of cached maps
      config.to_json # Returns Proc that is used to generate JSON. By default uses `JSON.dump` method
      config.to_json=(proc_value) # Changes proc to generate JSON.
      config.from_json # Returns Proc that is used to parse JSON. By default uses `JSON.load` method
      config.from_json=(proc_value) # Changes proc to parse JSON.

      # With context_metadata plugin:
      config.context_metadata.key # Key used to add metadata. By default it is :meta
      config.context_metadata.key=(value) # Changes key used to add context_metadata

      # With formatters plugin:
      config.formatters.add(key => proc_value)

      # With metadata plugin:
      config.metadata.attribute_keys # Shows allowed attributes keys when adding meta_attribute
      config.preloads.auto_preload_attributes_with_delegate # Shows this config value. Default is false
      config.preloads.auto_preload_attributes_with_serializer # Shows this config value. Default is false
      config.preloads.auto_hide_attributes_with_preload # Shows this config value. Default is false
      config.preloads.auto_preload_attributes_with_delegate=(bool) # Changes value
      config.preloads.auto_preload_attributes_with_serializer=(bool) # Changes value
      config.preloads.auto_hide_attributes_with_preload=(bool) # Changes value

      # With root plugin
      config.root # Shows current root config value. By default it is `{one: "data", many: "data"}`
      config.root=(one:, many:) # Changes root values.
      config.root.one # Shows root value used when serializing single object
      config.root.many # Shows root value used when serializing multiple objects
      config.root.one=(value) # Changes root value for serializing single object
      config.root.many=(value) # Changes root value for serializing multiple objects
  ```

- Added `from_json` config method that is used in `#as_json` result.
  It can be overwritten this way:
  ```ruby
    config.from_json = proc {...}
  ```

- Configured branch coverage checking

- Disabling caching of serialized attributes maps by default. This can be reverted with `config.max_cached_map_per_serializer_count = 50`

- Refactor validations. Remove `validate_modifiers` plugin. Modifiers are now validated by default. This can be changed globally with config option `config.check_initiate_params = false`. Or we can skip validation per serialization
  ```ruby
    SomeSerializer.(obj, only: ..., :with: ..., except: ..., check_initiate_params: false)
  ```

## [0.2.0] - 2022-08-01

- Remove `.relation` DSL method for simplicity. Just use `attribute :foo, serializer: Foo`. Method can be returned manually:
  ```ruby
  class Serega
    def self.relation(name, serializer:, **opts, &block)
      attribute(name, serializer: serializer, **opts, &block)
    end
  end
```

- Add config option for `:preload` plugin  - `:auto_preload_attributes_with_delegate`.
  ```ruby
    # Setup:
    class Serega
      plugin :preload, auto_preload_attributes_with_delegate: true
      # or
      plugin :preload
      config[:preload][:auto_preload_attributes_with_delegate] = true
    end
  ```

- Add option :delegate when defining attributes.
  Examples:
  ```ruby
    attribute :comments_count, delegate: { to: :user_stat }
    attribute :address_line_1, key: :line_1, delegate: { to: :address, allow_nil: true }
  ```

- Prohibit to use option :preload together with option :const (#23)

- Rename constants. Add prefix Serega for come classes. Previously in applications that use same class names this classes have to be defined with two colons "::".
  - Serega::Attribute -> Serega::SeregaAttribute
  - Serega::Convert -> Serega::SeregaConvert
  - Serega::ConvertItem -> Serega::SeregaConvertItem
  - Serega::Error -> Serega::SeregaError
  - Serega::Helpers -> Serega::SeregaHelpers
  - Serega::Map -> Serega::SeregaMap
  - Serega::Utils -> Serega::SeregaUtils
  - Serega::Validations -> Serega::SeregaValidations


## [0.1.5] - 2022-07-27

- Added config option `config[:preloads][:auto_hide_attributes_with_preload]` to `preloads` plugin. By default it is `false`.

- Plugin `validate_modifiers` now raises `Serega:AttributeNotExist` error when requested attribute not exists

- Change `preloads` plugin config option `config[:preloads][:auto_preload_relation] = true` to `config[:preloads][:auto_preload_attributes_with_serializer] = false`, so now there are no surprises where this preloads come from.

## [0.1.4] - 2022-07-25

- Fix context_metadata plugin error
  ```ruby
    wrong number of arguments (given 2, expected 1)
  ```

## [0.1.3] - 2022-07-25

- Fix activerecord_preloads plugin error
  ```ruby
    wrong number of arguments (given 2, expected 1)
  ```

## [0.1.2] - 2022-07-24

- Added :const attribute option to specify attribute with constant value

- Added `.call` and `#call` methods same as `.to_h` and `#to_h`. New methods were added as when we can serialize list of objects the result will be array, so `to_h` is a bit confusing

## [0.1.1] - 2022-07-13

- Fix validation and README docs about attribute option `:key`. Previously we validate option :method instead

## [0.1.0] - 2022-07-07

- Initial public release ([@aglushkov][])


[@aglushkov]: https://github.com/aglushkov
