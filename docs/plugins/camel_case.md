# Plugin :camel_case

By default, when we add an attribute like `attribute :first_name` it means:

- adding a `:first_name` key to the resulting hash
- adding a `#first_name` method call result as value

But it's often desired to respond with *camelCased* keys.
By default, this can be achieved by specifying the attribute name and method directly
for each attribute: `attribute :firstName, method: first_name`

This plugin transforms all attribute names automatically.
We use a simple regular expression to replace `_x` with `X` for the whole string.
We make this transformation only once when the attribute is defined.

You can provide custom transformation when adding the plugin,
for example `plugin :camel_case, transform: ->(name) { name.camelize }`

For any attribute camelCase-behavior can be skipped when
the `camel_case: false` attribute option provided.

This plugin transforms only attribute keys, without affecting the `root`,
`metadata` and `context_metadata` plugins keys.

If you wish to [select serialized fields][selecting_fields], you should
provide them camelCased.

```ruby
class AppSerializer < Serega
  plugin :camel_case
end

class UserSerializer < AppSerializer
  attribute :first_name
  attribute :last_name
  attribute :full_name, camel_case: false,
    value: proc { |user| [user.first_name, user.last_name].compact.join(" ") }
end

require "ostruct"
user = OpenStruct.new(first_name: "Bruce", last_name: "Wayne")
UserSerializer.to_h(user)
# => {firstName: "Bruce", lastName: "Wayne", full_name: "Bruce Wayne"}

UserSerializer.new(only: %i[firstName lastName]).to_h(user)
# => {firstName: "Bruce", lastName: "Wayne"}
```

[selecting_fields]: ../../README.md#selecting-fields
