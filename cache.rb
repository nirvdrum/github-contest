require 'memcache'

class Cache

  def self.cache_dir
    @@cache_dir ||= 'cache'
  end

  def self.fetch(key, &block)
    @@cache ||= {}

    # Return the cached value if already in memory.
    return @@cache[key] unless @@cache[key].nil?

    # Try to load from file.
    @@cache[key] = File.open(File.join(cache_dir, key), 'rb'){ |io| Marshal.load(io) } rescue nil
    return @@cache[key] unless @@cache[key].nil?

    # Barring all else, perform the operation to obtain value to cache.
    @@cache[key] = block.call
    File.open(File.join(cache_dir, key), 'wb'){ |f| Marshal.dump(@@cache[key], f) }

    @@cache[key]
  end
end