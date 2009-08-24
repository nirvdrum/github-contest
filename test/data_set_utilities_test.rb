require 'test_helper'
require 'data_loader'

class DataSetUtilitiesTest < Test::Unit::TestCase

  def test_cross_validation_sets
    data_items = [
            ['a', '1'],
            ['a', '2'],
            ['d', '3'],
            ['e', '4'],
            ['f', '5'],
            ['b', '1'],
            ['q', '6'],
            ['r', '7'],
            ['c', '1'],
    ]

    data_set = Ai4r::Data::DataSet.new(:data_items => data_items)
    data_set.stubs(:rand).returns(0) # Random data in tests is hard to test for.
    folds = data_set.stratify(3)

    expected = [
            [folds[1] + folds[2], folds[0]],
            [folds[2] + folds[0], folds[1]],
            [folds[0] + folds[1], folds[2]]
    ]

    actual = []
    data_set.cross_validation(3) do |training_set, test_set|
      actual << [training_set, test_set]
    end

    assert_equal expected, actual
  end

  def test_to_models
    data_set = DataLoader.load_watchings

    w1 = Watcher.new('1')
    w2 = Watcher.new('2')
    w3 = Watcher.new('5')

    r1 = Repository.new '1234', 'user_a/blah', '2009-02-26'
    r2 = Repository.new '2345', 'user_b/yo', '2009-05-17'
    r3 = Repository.new '6790', 'user_c/yo', '2009-03-19'

    r2.parent = r3

    w1.associate r1
    w1.associate r2
    w2.associate r2
    w3.associate r3

    actual = data_set.to_models

    # Check that the watchers were loaded correctly.
    actual_watchers = actual[:watchers]
    assert_equal({'1' => w1, '2' => w2, '5' => w3}, actual_watchers)

    assert_equal w1.repositories, actual_watchers[w1.id].repositories
    assert_equal w2.repositories, actual_watchers[w2.id].repositories
    assert_equal w3.repositories, actual_watchers[w3.id].repositories

    # Check that the repositories were loaded correctly.
    actual_repositories = actual[:repositories]
    assert_equal({'1234' => r1, '2345' => r2, '6790' => r3}, actual_repositories)

    assert_equal r1.watchers, actual_repositories[r1.id].watchers
    assert_equal r2.watchers, actual_repositories[r2.id].watchers
    assert_equal r3.watchers, actual_repositories[r3.id].watchers
  end

  def test_to_models_without_repositories
    data_set = DataLoader.load_predictings

    w1 = Watcher.new('1')
    w2 = Watcher.new('5')

    actual = data_set.to_models
    actual_watchers = actual[:watchers]
    assert_equal({'1' => w1, '5' => w2}, actual_watchers)

    assert actual_watchers[w1.id].repositories.empty?
    assert actual_watchers[w2.id].repositories.empty?
  end

end