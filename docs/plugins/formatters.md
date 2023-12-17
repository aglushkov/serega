### Plugin :formatters

Allows to define `formatters` and apply them to attribute values.

Config option `config.formatters.add` can be used to add formatters.

Attribute option `:format` can be used with the name of formatter or with
callable instance.

Formatters can accept up to 2 parameters (formatted object, context)

```ruby
class AppSerializer < Serega
  plugin :formatters, formatters: {
    iso8601: ->(value) { time.iso8601.round(6) },
    on_off: ->(value) { value ? 'ON' : 'OFF' },
    money: ->(value, ctx) { value / 10**ctx[:digits) }
    date: DateTypeFormatter # callable
  }
end

class UserSerializer < Serega
  # Additionally, we can add formatters via config in subclasses
  config.formatters.add(
    iso8601: ->(value) { time.iso8601.round(6) },
    on_off: ->(value) { value ? 'ON' : 'OFF' },
    money: ->(value) { value.round(2) }
  )

  # Using predefined formatter
  attribute :commission, format: :money
  attribute :is_logined, format: :on_off
  attribute :created_at, format: :iso8601
  attribute :updated_at, format: :iso8601

  # Using `callable` formatter
  attribute :score_percent, format: PercentFormmatter # callable class
  attribute :score_percent, format: proc { |percent| "#{percent.round(2)}%" }
end
```
