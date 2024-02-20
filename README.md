# LeveledCache

An `ActiveSupport::Cache::Store` implementation that acts as a proxy over multiple caches ("levels") that are called in order. Caches specified earlier are checked for values earlier.

A typical use-case is to put a smaller, faster `ActiveSupport::Cache::MemoryStore` in front of a larger, slower `ActiveSupport::Cache::RedisCacheStore` to keep the hottest keys populated close to application code.

All interactions use the underlying caches' public APIs, which means that an interaction on the LeveledProxy potentially serializes and compresses the data multiple times as the interaction progresses through levels. Take care to configure underlying caches accordingly. For example, it may be desirable to use `NullCoder` on an outer `ActiveSupport::Cache::MemoryStore`.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add leveled_cache

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install leveled_cache

## Usage

```ruby
FastCache = ActiveSupport::Cache::MemoryStore.new     # fast, in-process cache
SlowCache = ActiveSupport::Cache::RedisCacheStore.new # slow, out-of-process cache

cache = LeveledCache::Store.new(FastCache, SlowCache)

cache.fetch("key") do
  # 1. Fetch from FastCache
  # 2. If missing, fetch from SlowCache and populate FastCache
  # 3. If missing, run block, populate SlowCache and FastCache
  compute_expensive_value
end

cache.fetch_multi("key1", "key2") do |key|
  # 1. fetch_multi from FastCache
  # 2. For any missing values, fetch_multi from SlowCache and populate FastCache
  # 3. For any missing values, run block, populate SlowCache and FastCache
  compute_expensive_value_for(key)
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dpirotte/leveled_cache. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/dpirotte/leveled_cache/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the LeveledCache project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dpirotte/leveled_cache/blob/main/CODE_OF_CONDUCT.md).
