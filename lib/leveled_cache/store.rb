# frozen_string_literal: true

require "active_support/cache"
require "active_support/notifications"

module LeveledCache
  # A cache store implementation that acts as a proxy over multiple caches
  # ("levels") that are called in order. Caches specified earlier are
  # checked for values earlier.
  #
  # A typical use-case is to put a fast, in-process MemoryStore in front of
  # a larger, slower RedisCacheStore:
  #
  #   cache = LeveledCache::Store.new(
  #     ActiveSupport::Cache::MemoryStore.new,
  #     ActiveSupport::Cache::RedisCacheStore.new,
  #   )
  #
  # All interactions use the underlying caches' public APIs, which means
  # an interaction on the LeveledProxy potentially serialized, compressed,
  # etc. multiple times as the interaction progresses through levels. Take
  # care to configure underlying caches accordingly. For example, it may
  # be desirable to use NullCoder on an earlier MemoryStore.
  class Store < ActiveSupport::Cache::Store
    # Create a new LeveledCacheProxy that calls cache methods on
    # one or more underlying caches in order.
    #
    # ==== Options
    #
    # No options are allowed. Set options on the caches provided.
    #
    def initialize(*caches)
      @caches = caches
      @options = {}
    end

    # Fetches data from the caches in order using the given key. Data
    # is returned from the first cache with data for the given key.
    #
    # Internally, +fetch+ is called on each cache level recursively
    # until data is found. If data is missing from "earlier" caches but
    # found in "later" caches, all "earlier" caches will populate with
    # the found data.
    #
    # If no data is found in any caches, the block is called and all
    # caches are populated with the return value.
    #
    # Options are passed through to the underlying caches.
    def fetch(name, **options, &)
      _fetch(@caches, name, options, &)
    end

    # Fetches data from the caches in order using the given keys. Data
    # is returned from the first cache with data for the given keys.
    #
    # If no data is found in any caches, the block is called and all
    # caches are populated with the return value.
    #
    # Options are passed through to the underlying caches.
    def fetch_multi(*names, **options, &)
      _fetch_multi(@caches, names, options, &)
    end

    # Reads data from the caches in order using the given key. Data
    # is returned from the first cache level with data for the given
    # key. Otherwise, +nil+ is returned.
    #
    # Options are passed through to the underlying caches.
    def read(name, **options)
      read_entry(name, **options)
    end

    # Reads data from the caches in order using the given keys. Data
    # is returned from the first cache level with data for a key.
    # Otherwise, +{}+ is returned.
    #
    # Options are passed through to the underlying caches.
    def read_multi(*names, **options)
      read_multi_entries(names, **options)
    end

    # Writes the value to all cache levels with the provided key.
    #
    # Options are passed through to the underlying caches.
    def write(name, value, **options)
      write_entry(name, value, **options)
    end

    def delete(name, **options)
      delete_entry(name, **options)
    end

    # Writes the key value pairs to all cache levels.
    #
    # Options are passed through to the underlying caches.
    def write_multi(hash, **options)
      write_multi_entries(hash, **options)
    end

    private

    # Recursively `fetch_multi` on each cache. Missing values
    # will attempt to `fetch_multi` from the next cache level
    # until all values are returned, or the block is called.
    def _fetch_multi(caches, names, options, &)
      first, *rest = caches

      reads = if first.is_a?(self.class)
        first.fetch_multi(*names, **options, &)
      else
        first.read_multi(*names, **options)
      end

      missing = names - reads.keys

      if missing.any?
        writes = if rest.any?
          _fetch_multi(rest, missing, options, &)
        else
          missing.index_with(&)
        end

        first.write_multi(writes, **options)
        reads.merge!(writes)
      end

      reads
    end

    # Recursively `fetch` on each cache level until a value
    # is returned or the block is called.
    def _fetch(caches, name, options, &block)
      first, *rest = caches

      first.fetch(name, **options) do
        if rest.any?
          _fetch(rest, name, options, &block)
        else
          block.call
        end
      end
    end

    def read_entry(key, **options)
      @caches.lazy.map do |cache|
        cache.read(key, **options)
      end.compact.first
    end

    def write_entry(key, entry, **options)
      @caches.map do |cache|
        cache.write(key, entry, **options)
      end
    end

    def delete_entry(key, **options)
      @caches.map do |cache|
        cache.delete(key, **options)
      end
    end

    def read_multi_entries(*keys, **options)
      _read_multi_entries(@caches, *keys, **options)
    end

    def _read_multi_entries(caches, keys, **options)
      first, *rest = caches

      reads = first.read_multi(*keys, **options)

      missing = keys - reads.keys

      if missing.any? && rest.any?
        reads.merge!(_read_multi_entries(rest, missing, **options))
      end

      reads
    end

    def write_multi_entries(hash, **options)
      @caches.map do |cache|
        cache.write_multi(hash)
      end
    end
  end
end
