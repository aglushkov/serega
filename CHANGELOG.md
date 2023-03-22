## [Unreleased]

- Plugin `:if` was added, look at README.md for all options and examples.
- Plugin `:hide_nil` was removed, but it can be replaced by plugin `:if`
```ruby
# previously
plugin :hide_nil
attribute :email, hide_nil: true

# now
plugin :if
attribute :email, unless_value: :nil?
```

## [0.8.3] - 2023-02-14
  - Allow to call serialize methods with `nil` as options
    ```
      UserSerialzier.to_h(user, nil) # same as UserSerialzier.to_h(user)
      UserSerialzier.new(nil).to_h(user, nil)  # same as UserSerialzier.new.to_h(user)
    ```
  - Optimize allocations
  - Add documentation coverage checks in RELEASE.md
  - Add allocate_stats gem to easily check extra allocations

## [0.8.2] - 2022-12-20

- Show current serializer and attribute when NoMethodError happens
- Fix auto preload, that should not be added for attributes with :serializer and :batch options

## [0.8.1] - 2022-12-11

- Change requested fields validation message. Now we return all not existing fields instead of first one.

## [0.8.0] - 2022-12-09

- Add `:key` option to `:delegate` option. Remove possibility to add top-level `:key` option together with `:delegate` option
  ```ruby
    # BEFORE
    attribute :is_presale, delegate: { to: :product }, key: :presale?

    # NOW
    attribute :is_presale, delegate: { to: :product, key: :presale? }
  ```

## [0.7.0] - 2022-12-08

- Root plugin now does not symbolize provided root key
- Root plugin now allows to provide `nil` root to skip adding root
- Metadata and context_metadata plugins now raise error if root plugin was not added before manually
- Metadata and context_metadata not added if root is nil
- More documentation with yardoc
- Require :preloads plugin to be added manually before :activerecord_preloads

## [0.6.1] - 2022-12-03

- Fix `presenter` plugin was not working for nested serializers
- Fix issue with not auto-preloaded relations when using #call method
- Remove SeregaSerializer class, moved its functionality to Serega#serialize method

## [0.6.0] - 2022-12-01
- Make batch loader to accept current point instead of nested points as 3rd parameter.

  It becomes easier to find preloads by asking `point.preloads`

## [0.5.2] - 2022-11-21

- Change gem description again

## [0.5.1] - 2022-11-21

- Change gem summary, description, changelog link
- Fix README links

## [0.5.0] - 2022-11-21

- Add plugin :batch for batch loading
  ```ruby
    class PostSerializer < Serega
      plugin :batch

      # Define batch loader via callable class, it must accept three args (keys, context, nested_attributes)
      attribute :comments_count, batch: { key: :id, loader: PostCommentsCountBatchLoader, default: 0}

      # Define batch loader via Symbol, later we should define this loader via config.batch_loaders.define(:posts_comments_counter) { ... }
      attribute :comments_count, batch: { key: :id, loader: :posts_comments_counter, default: 0}

      # Define batch loader with serializer
      attribute :comments, serializer: CommentSerializer, batch: { key: :id, loader: :posts_comments, default: []}

      # Resulted block must return hash like { key => value(s) }
      config.batch_loaders.define(:posts_comments_counter) do |keys|
        Comment.group(:post_id).where(post_id: keys).count
      end

      # We can return objects that will be automatically serialized if attribute defined with :serializer
      # Parameter `context` can be used when loading batch
      # Parameter `points` can be used to find nested attributes that will be serialized
      config.batch_loaders.define(:posts_comments) do |keys, context, points|
        Comment.where(post_id: keys).where(is_spam: false).group_by(&:post_id)
      end
    end
  ```

## [0.4.0] - 2022-09-20

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
