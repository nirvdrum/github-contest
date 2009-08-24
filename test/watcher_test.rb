require 'test_helper'
require 'watcher'
require 'repository'
require 'data_loader'

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
    assert_equal [one.id, two.id], @watcher.repositories

    # Make sure a repository can only appear once.
    @watcher.repositories << one
    assert_equal [one.id, two.id], @watcher.repositories
  end

  def test_to_s
    assert_equal '1', @watcher.to_s

    one = Repository.new '1234', 'user_a/yo', '2009-02-26'
    two = Repository.new '2345', 'user_b/blah', '2009-03-18'

    @watcher.repositories << one
    assert_equal '1:1234', @watcher.to_s

    @watcher.repositories << two
    assert_equal '1:1234,2345', @watcher.to_s
  end

  def test_equality
    first = Watcher.new '1'
    second = Watcher.new '1'

    assert first == second

    third = Watcher.new '2'
    assert first != third

    # Watchers do not care about repositories for matters of equality.
    first.repositories << Repository.new('1234', 'user_a/blah', '2009-05-23')
    assert first == second
  end

  def test_eql
    first = Watcher.new '1'
    second = Watcher.new '1'

    assert first.eql?(second)
    assert first.hash == second.hash

    third = Watcher.new '2'
    assert !first.eql?(third)
    assert first.hash != third.hash

    # Watchers do not care about repositories for matters of equality.
    first.repositories << Repository.new('1234', 'user_a/blah', '2009-05-23')
    assert first.eql?(second)
    assert first.hash == second.hash
  end 

  def test_associate
    watcher = Watcher.new '1'
    repo = Repository.new '1234'

    watcher.associate repo

    # Check that bi-directional mappings are set up.
    assert_equal [repo.id], watcher.repositories
    assert_equal [watcher.id], repo.watchers
  end

end