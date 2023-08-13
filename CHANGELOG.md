# CHANGELOG

## [Unreleased]

- Remove :openapi plugin. It was wrong place to add this plugin.
  Serializers should be good at one thing - serialization.
  Serializers classes just don't know all needed context to build good schema.
  You can use this gist as an example how to build OpenAPI schema for Serega
  serializer for ActiveRecord objects: <https://gist.github.com/aglushkov/60e3ac1525a940cc6a144c92822556e5>

## [0.14.0] - 2023-07-24

- Add :explicit_many_option plugin
- Add '.openapi_properties' method to specify openapi_properties
- Remove :openapi attribute option from :openapi plugin (replaced with openapi_properties)

## [0.13.0] - 2023-07-20

- Add :openapi gem that helps to construct OpenAPI schema for serializer.
  It can help to construct response schemas and use with some OpenAPI tools
  (for example with rswag gem). Look at README for more information

## [0.12.0] - 2023-07-10

- Fix issue <https://github.com/aglushkov/serega/issues/85>
  With this issue fixed we now require to provide `:preload_path` attribute
  option when preloaded more than one association. Before this change we preload
  nested associations only to the latest specified association. Please see
  README `preload` plugin section for more details.

## [0.11.2] - 2023-04-30

- Raise meaningful error when :batch plugin not enabled for root serializer.
  Workaround for issue <https://github.com/aglushkov/serega/issues/94> - it is
  not a bug, it is how `batch` plugin works.

```ruby
# Before:
# => NoMethodError:
#    undefined method get for nil:NilClass in
#    remember_key_for_batch_loading method
#
# After:
# => Serega::SeregaError:
#    Plugin :batch must be added to current serializer (#{current_serializer})
#    to load attributes with :batch option in nested serializer
#    (#{nested_serializer})
#
```

## [0.11.1] - 2023-04-25

- Fix :default_key batch plugin option was set to nil when defined as
  `plugin :batch, default_key: :id`

## [0.11.0] - 2023-04-24

### Breaking changes

- Rename `SeregaMap` class to `SeregaPlan` and `SeregaMapPoint` to `SeregaPlanPoint`
- Rename config option from `max_cached_map_per_serializer_count` to
  `max_cached_plans_per_serializer_count`
- Rename config method from `config.batch_loaders` to `config.batch.loaders`
- Rename config method from `config.batch_loaders.define` to `config.batch.define`

### Improvements

- Add config method `config.batch.auto_hide=(bool)` to automatically mark as
  hidden attributes having :batch option
- Allow to define :batch plugin with :auth_hide option
- Allow to define :batch plugin with :default_key option

```ruby
class SomeSerializer < Serega
  plugin :batch, auto_hide: true, default_key: :id

  # or
  plugin :batch
  config.batch.auto_hide = true
  config.batch.default_key = :id
end
```

- Add `config.delegate_default_allow_nil=(bool)` config option to specify
  default behavior when delegated object is nil. By default it is `false`

```ruby
class SomeSerializer < Serega
  config.delegate_default_allow_nil = true
end
```

## [0.10.0] - 2023-03-28

- Less strict attribute name format. Allow attribute names to include chars
  "\_", "-" and "~". They can be added as first or last characters also.
- Allow to disable attribute name format check globally or per-serializer via:

```ruby
Serega.config.check_attribute_name = false

class SomeSerializer < Serega
  config.check_attribute_name = false
end
```

- Added comments in code about where each methods extended
- Allow to load :if plugin and :batch plugin in any order
- Less objects allocations when parsing string modifiers

## [0.9.0] - 2023-03-23

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
- Fix auto preload, that should not be added for attributes with
  :serializer and :batch options

## [0.8.1] - 2022-12-11

- Change requested fields validation message. Now we return all not existing
  fields instead of first one.

## [0.8.0] - 2022-12-09

- Add `:key` option to `:delegate` option. Remove possibility to add top-level
  `:key` option together with `:delegate` option

```ruby
  # BEFORE
  attribute :is_presale, delegate: { to: :product }, key: :presale?

  # NOW
  attribute :is_presale, delegate: { to: :product, key: :presale? }
```

## [0.7.0] - 2022-12-08

- Root plugin now does not symbolize provided root key
- Root plugin now allows to provide `nil` root to skip adding root
- Metadata and context_metadata plugins now raise error if root plugin was not
  added before manually
- Metadata and context_metadata not added if root is nil
- More documentation with yardoc
- Require :preloads plugin to be added manually before :activerecord_preloads

## [0.6.1] - 2022-12-03

- Fix `presenter` plugin was not working for nested serializers
- Fix issue with not auto-preloaded relations when using #call method
- Remove SeregaSerializer class, moved its functionality to Serega#serialize
  method

## [0.6.0] - 2022-12-01

- Make batch loader to accept current point instead of nested points as 3rd
  parameter.

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

    # Define batch loader via callable class, it must accept three args
    # (keys, context, nested_attributes)
    attribute :comments_count,
      batch: { key: :id, loader: PostCommentsCountBatchLoader, default: 0}

    # Define batch loader via Symbol, later we should define this loader via
    # config.batch_loaders.define(:posts_comments_counter) { ... }
    attribute :comments_count,
      batch: { key: :id, loader: :posts_comments_counter, default: 0}

    # Define batch loader with serializer
    attribute :comments,
      serializer: CommentSerializer,
      batch: { key: :id, loader: :posts_comments, default: []}

    # Resulted block must return hash like { key => value(s) }
    config.batch_loaders.define(:posts_comments_counter) do |keys|
      Comment.group(:post_id).where(post_id: keys).count
    end

    # We can return objects that will be automatically serialized if attribute
    # defined with :serializer
    #
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

- Use Oj JSON adapter by default if Oj is loaded. We use `mode: :compat` when
  serializing objects. Config can still be overwritten:

```ruby
 config.to_json = proc { |data| Oj.dump(mode: :strict) }
 config.from_json = proc { |json| Oj.load(json) }
```

- We can now access config options through methods instead of hash keys

```ruby
# Shows enabled plugins
config.plugins

# Shows allowed options keys when initiating serializer
config.initiate_keys

# Shows allowed options keys when adding new attribute
config.attribute_keys

# Shows allowed options keys when serializing object with
 #call, #to_h, #to_json, #as_json methods
config.serialize_keys

# Shows value of check_initiate_params option. Default is true
config.check_initiate_params

# Changes check_initiate_params option. When value is false - it skips invalid
# initiate options and values
config.check_initiate_params=(bool_value)

# Shows count of cached maps per serializer. Default is 0
config.max_cached_map_per_serializer_count

# Changes count of cached maps
config.max_cached_map_per_serializer_count=(int_value)

# Returns Proc that is used to generate JSON. By default uses `JSON.dump` method
config.to_json

# Changes proc to generate JSON.
config.to_json=(proc_value)

# Returns Proc that is used to parse JSON. By default uses `JSON.load` method
config.from_json

# Changes proc to parse JSON.
config.from_json=(proc_value)

# With context_metadata plugin:
# Key used to add metadata. By default it is :meta
config.context_metadata.key

# Changes key used to add context_metadata
config.context_metadata.key=(value)

# With formatters plugin:
# Add formatters
config.formatters.add(key => proc_value)

# With metadata plugin:
# Shows allowed attributes keys when adding meta_attribute
config.metadata.attribute_keys

# With preloads plugin:
# Shows this config value. Default is false
config.preloads.auto_preload_attributes_with_delegate

# Shows this config value. Default is false
config.preloads.auto_preload_attributes_with_serializer

# Shows this config value. Default is false
config.preloads.auto_hide_attributes_with_preload

# Changes value
config.preloads.auto_preload_attributes_with_delegate=(bool)

# Changes value
config.preloads.auto_preload_attributes_with_serializer=(bool)

# Changes value
config.preloads.auto_hide_attributes_with_preload=(bool)

# With root plugin
# Shows current root config value. By default it is `{one: "data", many: "data"}`
config.root

# Changes root values.
config.root=(one:, many:)

# Shows root value used when serializing single object
config.root.one

# Shows root value used when serializing multiple objects
config.root.many

# Changes root value for serializing single object
config.root.one=(value)

# Changes root value for serializing multiple objects
config.root.many=(value)
```

- Added `from_json` config method that is used in `#as_json` result.
  It can be overwritten this way:

```ruby
config.from_json = proc {...}
```

- Configured branch coverage checking

- Disabling caching of serialized attributes maps by default. This can be
  reverted with `config.max_cached_map_per_serializer_count = 50`

- Refactor validations. Remove `validate_modifiers` plugin. Modifiers are now
  validated by default. This can be changed globally with config option
  `config.check_initiate_params = false`. Or we can skip validation per
  serialization

```ruby
SomeSerializer.
  (obj, only: ..., :with: ..., except: ..., check_initiate_params: false)
```

## [0.2.0] - 2022-08-01

- Remove `.relation` DSL method for simplicity. Just use
  `attribute :foo, serializer: Foo`. Method can be added back manually:

```ruby
  class Serega
    def self.relation(name, serializer:, **opts, &block)
      attribute(name, serializer: serializer, **opts, &block)
    end
  end
```

- Add config option for `:preload` plugin -
  `auto_preload_attributes_with_delegate`

```ruby
# Setup:
class Serega
  plugin :preload, auto_preload_attributes_with_delegate: true

  # or
  plugin :preload
  config[:preload][:auto_preload_attributes_with_delegate] = true
end
```

- Add option :delegate when defining attributes. Examples:

```ruby
  attribute :comments_count,
    delegate: { to: :user_stat }

  attribute :address_line_1, key: :line_1,
    delegate: { to: :address, allow_nil: true }
```

- Prohibit to use option :preload together with option :const (#23)

- Rename constants. Add prefix Serega for come classes.
  Previously in applications that use same class names this classes have to be
  defined with two colons "::".

   - Serega::Attribute -> Serega::SeregaAttribute
   - Serega::Convert -> Serega::SeregaConvert
   - Serega::ConvertItem -> Serega::SeregaConvertItem
   - Serega::Error -> Serega::SeregaError
   - Serega::Helpers -> Serega::SeregaHelpers
   - Serega::Map -> Serega::SeregaMap
   - Serega::Utils -> Serega::SeregaUtils
   - Serega::Validations -> Serega::SeregaValidations

## [0.1.5] - 2022-07-27

- Added config option `config[:preloads][:auto_hide_attributes_with_preload]`
  to `preloads` plugin. By default it is `false`.

- Plugin `validate_modifiers` now raises `Serega:AttributeNotExist` error when
  requested attribute not exists

- Change `preloads` plugin config option
  `config[:preloads][:auto_preload_relation] = true` to
  `config[:preloads][:auto_preload_attributes_with_serializer] = false`,
  so now there are no surprises where this preloads come from.

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

- Added `.call` and `#call` methods same as `.to_h` and `#to_h`. New methods
  were added as when we can serialize list of objects the result will be array,
  so `to_h` is a bit confusing

## [0.1.1] - 2022-07-13

- Fix validation and README docs about attribute option `:key`.
  Previously we validate option :method instead

## [0.1.0] - 2022-07-07

- Initial public release ([@aglushkov][])

[@aglushkov]: https://github.com/aglushkov
