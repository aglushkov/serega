# Plugin :metadata

Depends on: [`:root`][root] plugin, that must be loaded first

Adds ability to describe metadata and adds it to serialized response

Adds class-level `.meta_attribute` method. It accepts:

- `*path` [Array of Symbols] - nested hash keys.
- `**options` [Hash]

   - `:const` - describes metadata value (if it is constant)
   - `:value` - describes metadata value as any `#callable` instance
   - `:hide_nil` - does not show the metadata key if the value is nil.
     It is `false` by default
   - `:hide_empty` - does not show the metadata key if the value is nil or empty.
     It is `false` by default.

- `&block` [Proc] - describes value for the current meta attribute

```ruby
class AppSerializer < Serega
  plugin :root
  plugin :metadata

  meta_attribute(:version, const: '1.2.3')
  meta_attribute(:ab_tests, :names, value: ABTests.new.method(:names))
  meta_attribute(:meta, :paging, hide_nil: true) do |records, ctx|
    next unless records.respond_to?(:total_count)

    {
      page: records.page,
      per_page: records.per_page,
      total_count: records.total_count
    }
  end
end

AppSerializer.to_h(nil)
# => {:data=>nil, :version=>"1.2.3", :ab_tests=>{:names=> ... }}
```

[root]: root.md
