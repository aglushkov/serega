# Plugin :context_metadata

Depends on: [`:root`][root] plugin, that must be loaded first

Allows to provide metadata and attach it to serialized response.

Accepts option `:context_metadata_key` with the name of the root metadata keyword.
By default, it has the `:meta` value.

The key can be changed in children serializers using this method:
`config.context_metadata.key=(value)`.

```ruby
class UserSerializer < Serega
  plugin :root, root: :data
  plugin :context_metadata, context_metadata_key: :meta

  # Same:
  # plugin :context_metadata
  # config.context_metadata.key = :meta
end

UserSerializer.to_h(nil, meta: { version: '1.0.1' })
# => {:data=>nil, :version=>"1.0.1"}
```

[root]: root.md
