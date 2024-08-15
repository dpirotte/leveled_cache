## [0.3.0] - 2024-08-15

- Optimize `read_multi`
- Implement `write_multi`
- Fix `delete` so that keys aren't double-namespaced
- Support nested `LeveledCache`

## [0.2.0] - 2024-02-26

- Support `ActiveSupport::Cache.lookup_store`
- `#write` and `#delete` now return responses from underlying caches

## [0.1.0] - 2024-02-13

- Initial release
