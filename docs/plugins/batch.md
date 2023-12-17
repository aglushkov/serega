### Plugin :batch

Helps to omit N+1.

User must specify how attribute values are loaded -
`attribute :foo, batch: {loader: SomeLoader, id_method: :id}`.

The result must be returned as Hash, where each key is one of the provided IDs.

```ruby
class AppSerializer
  plugin :batch
end

class UserSerializer < AppSerializer
  attribute :comments_count,
    batch: { loader: SomeLoader, id_method: :id }

  attribute :company,
    batch: { loader: SomeLoader, id_method: :id },
    serializer: CompanySerializer
end
```

#### Option :loader

Loaders can be defined as a Proc, a callable value, or a named Symbol
Named loaders should be predefined with
`config.batch.define(:loader_name) { |ids| ... })`

The loader can accept 1 to 3 arguments:

1. List of IDs (each ID will be found by using the `:id_method` option)
1. Context
1. PlanPoint - a special object containing information about current
   attribute and all children and parent attributes. It can be used to preload
   required associations to batch values.
   See [example](examples/batch_loader.rb) how
   to find required preloads when using the `:preloads` plugin.

```ruby
class AppSerializer < Serega
  plugin :batch, id_method: :id
end

class UserSerializer < Serega
  # Define loader as a callable object
  attribute :comments_count,
    batch: { loader: CountLoader }

  # Define loader as a Proc
  attribute :comments_count,
    batch: { loader: proc { |ids| CountLoader.call(ids) } }

  # Define loader as a Symbol
  config.batch.define(:comments_count_loader) { |ids| CountLoader.call(ids }
  attribute :comments_count, batch: { loader: :comments_count_loader }
end

class CountLoader
  def self.call(user_ids)
    Comment.where(user_id: user_ids).group(:user_id).count
  end
end
```

#### Option :id_method

The `:batch` plugin can be added with the global `:id_method` option. It can be
a Symbol, Proc or any callable value that can accept the current object and
context.

```ruby
class SomeSerializer
  plugin :batch, id_method: :id
end

class UserSerializer < AppSerializer
  attribute :comments_count,
    batch: { loader: CommentsCountBatchLoader } # no :id_method here anymore

  attribute :company,
    batch: { loader: UserCompanyBatchLoader }, # no :id_method here anymore
    serializer: CompanySerializer
end

```

However, the global `id_method` option can be overwritten via
`config.batch.id_method=` method or in specific attributes with the `id_method`
option.

```ruby
class SomeSerializer
  plugin :batch, id_method: :id # global id_method is `:id`
end

class UserSerializer < AppSerializer
  # :user_id will be used as default `id_method` for all batch attributes
  config.batch.id_method = :user_id

  # id_method is :user_id
  attribute :comments_count,
    batch: { loader: CommentsCountBatchLoader }


  # id_method is :user_id
  attribute :company,
    batch: { loader: UserCompanyBatchLoader }, serializer: CompanySerializer

  # id_method is :uuid
  attribute :points_amount,
    batch: { loader: PointsBatchLoader, id_method: :uuid }
end
```

#### Default value

The default value for attributes without found value can be specified via
`:default` option. By default, attributes without found value will be
serialized as a `nil` value. Attributes marked as `many: true` will be
serialized as empty array `[]` values.

```ruby
class UserSerializer < AppSerializer
  # Missing values become empty arrays, as the `many: true` option is specified
  attribute :companies,
    batch: {loader: proc {}},
    serializer: CompanySerializer,
    many: true

  # Missing values become `0` as specified directly
  attribute :points_amount, batch: { loader: proc {} }, default: 0
end
```

Batch attributes can be marked as hidden by default if the plugin is enabled
with the `auto_hide` option. The `auto_hide` option can be changed with
the `config.batch.auto_hide=` method.

Look at [select serialized fields](#selecting-fields) for more information
about hiding/showing attributes.

```ruby
class AppSerializer
  plugin :batch, auto_hide: true
end

class UserSerializer < AppSerializer
  config.batch.auto_hide = false
end
```

---
⚠️ ATTENTION: The `:batch` plugin must be added to all serializers that have
`:batch` attributes inside nested serializers. For example, when you serialize
the `User -> Album -> Song` and the Song has a `batch` attribute, then
the `:batch` plugin must be added to the User serializer.

The best way would be to create one parent `AppSerializer < Serega` serializer
and add the `:batch` plugin once to this parent serializer.
