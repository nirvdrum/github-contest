require 'test_helper'
require 'watcher'
require 'repository'

class WatcherTest < Test::Unit::TestCase

  def setup
    @watcher = Watcher.new '1'
  end

  def test_new
    id = '1'

    w = Watcher.new id

    assert_equal id, w.id
  end

  def test_add_repository
    one = Repository.new '1234', 'user_a/yo', '2009-02-26'
    two = Repository.new '2345', 'user_b/blah', '2009-03-18'

    @watcher.repositories << one
    @watcher.repositories << two

    # Make sure the repositories set was updated properly.
    assert_equal [one, two], @watcher.repositories

    # Make sure a repository can only appear once.
    @watcher.repositories << one
    assert_equal [one, two], @watcher.repositories

    # Make sure the bi-directional relationship was established.
    assert_equal [@watcher], one.watchers
    assert_equal [@watcher], two.watchers
  end

  def test_to_s
    assert_equal '1', @watcher.to_s

    one = Repository.new '1234', 'user_a/yo', '2009-02-26'
    two = Repository.new '2345', 'user_b/blah', '2009-03-18'

    @watcher.repositories << one
    assert_equal '1:1234', @watcher.to_s

    @watcher.repositories << two
    assert_equal '1:1234\n1:2345', @watcher.to_s
  end

  def test_equality
    first = Watcher.new '1'
    second = Watcher.new '1'

    assert first == second

    third = Watcher.new '2'
    assert first != third
  end

end