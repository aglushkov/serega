### Plugin :depth_limit

Helps to secure from malicious queries that serialize too much
or from accidental serializing of objects with cyclic relations.

Depth limit is checked when constructing a serialization plan, that is when
`#new` method is called, ex: `SomeSerializer.new(with: params[:with])`.
It can be useful to instantiate serializer before any other business logic
to get possible errors earlier.

Any class-level serialization methods also check the depth limit as they also
instantiate serializer.

When the depth limit is exceeded `Serega::DepthLimitError` is raised.
Depth limit error details can be found in the additional
`Serega::DepthLimitError#details` method

The limit can be checked or changed with the next config options:

- `config.depth_limit.limit`
- `config.depth_limit.limit=`

There is no default limit, but it should be set when enabling the plugin.

```ruby
class AppSerializer < Serega
  plugin :depth_limit, limit: 10 # set limit for all child classes
end

class UserSerializer < AppSerializer
  config.depth_limit.limit = 5 # overrides limit for UserSerializer
end
```
