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

  def test_from_data_set_with_repositories
    data_set = DataLoader.load_watchings("#{File.dirname(__FILE__)}/data")

    w1 = Watcher.new('1')
    w2 = Watcher.new('2')
    w3 = Watcher.new('5')

    r1 = Repository.new '1234'
    r2 = Repository.new '2345'
    r3 = Repository.new '6790'

    w1.repositories << r1
    w1.repositories << r2
    w2.repositories << r2
    w3.repositories << r3

    actual = Watcher.from_data_set(data_set)
    assert_equal({'1' => w1, '2' => w2, '5' => w3}, actual)

    assert_equal w1.repositories, actual.values[0].repositories
    assert_equal w2.repositories, actual.values[1].repositories
    assert_equal w3.repositories, actual.values[2].repositories
  end

  def test_from_data_set_without_repositories
    data_set = DataLoader.load_predictings("#{File.dirname(__FILE__)}/data")

    w1 = Watcher.new('1')
    w2 = Watcher.new('5')

    actual = Watcher.from_data_set(data_set)
    assert_equal({'1' => w1, '5' => w2}, actual)

    assert actual.values[0].repositories.empty?
    assert actual.values[1].repositories.empty?
  end

end