require 'test_helper'
require 'cache'
require 'memcache'

class CacheTest < Test::Unit::TestCase

  def test_fetch
    cache = {}
    MemCache.stubs(:new).returns(cache)

    # Check that upon initial access, we get the value from the block.
    val = Cache.fetch('key') { 7 }
    assert_equal 7, val

    # Check that upon subsequent access, we get the already written value.
    new_val = Cache.fetch('key') { 9 }
    assert_equal 7, val  
  end

end