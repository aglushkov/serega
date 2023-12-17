### Plugin :explicit_many_option

The plugin requires adding a `:many` option when adding relationships
(attributes with the `:serializer` option).

Adding this plugin makes it clearer to find if some relationship is an array or
a single object.

```ruby
  class BaseSerializer < Serega
    plugin :explicit_many_option
  end

  class UserSerializer < BaseSerializer
    attribute :name
  end

  class PostSerializer < BaseSerializer
    attribute :text
    attribute :user, serializer: UserSerializer, many: false
    attribute :comments, serializer: PostSerializer, many: true
  end
```
