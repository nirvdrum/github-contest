require 'memcache'

class Cache

  def self.fetch(key, &block)
    @@cache ||= MemCache.new('localhost:11211', :namespace => 'gh', :multithread => true)

    return @@cache[key] unless @@cache[key].nil?

    value = block.call

    begin
      @@cache[key] = value
    rescue MemCache::MemCacheError => e
      # Eat the exception since there's nothing we can do about it.
      $LOG.error "Failed to store item in cache for key '#{key}': #{e}"
    end

    value
  end 

end