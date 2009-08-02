require 'test_helper'
require 'repository'
require 'nearest_neighbors'
require 'watcher'

class NearestNeighborsTest < Test::Unit::TestCase

  def setup
    @one = Repository.new '1234', 'user_a/yo', '2009-02-26'
    @two = Repository.new '4567', 'user_b/blah', '2009-03-17'
  end

  def test_euclidian_distance_no_match
    ensure_symmetry(Float::MAX)
  end

  def test_euclidian_distance_by_watchers
    w1 = Watcher.new '1'
    w2 = Watcher.new '2'
    w3 = Watcher.new '3'

    # No matches.
    @one.watchers << w1
    ensure_symmetry(Float::MAX)

    # Exact match.
    @two.watchers << w1
    ensure_symmetry(0)

    # Overlap with @one having more watchers.
    @one.watchers << w2
    ensure_symmetry(1)

    # Overlap with @one and @two differing by 1 watcher.
    @two.watchers << w3
    ensure_symmetry(1)
  end

  def test_euclidian_distance_by_watcher_size
    w1 = Watcher.new '1'
    w2 = Watcher.new '2'
    w3 = Watcher.new '3'
    w4 = Watcher.new '4'
    w5 = Watcher.new '5'

    three = Repository.new '3', 'user_c/hey', '2009-04-09'

    # All three repositories will have w1 in common.
    @one.watchers << w1
    @two.watchers << w1
    three.watchers << w1

    # @two will have one additional watcher.
    @two.watchers << w2

    # three will have four additional watchers.
    three.watchers << w2
    three.watchers << w3
    three.watchers << w4
    three.watchers << w5

    ensure_symmetry(1, @one, @two)
    ensure_symmetry(0.25, @one, three)
  end

  def test_accuracy
    actual = Watcher.new '1'
    predicted = Watcher.new '2'

    # Exact match should be 1.0.
    assert_equal 1.0, NearestNeighbors.accuracy(actual, predicted)

    # Exact match should be 1.0.
    @one.watchers << actual
    @one.watchers << predicted
    assert_equal 1.0, NearestNeighbors.accuracy(actual, predicted)
  end

  def test_accuracy_negatives
    actual = Watcher.new '1'
    predicted = Watcher.new '2'

    # No matches should be -1.0.
    @one.watchers << predicted
    assert_equal -1.0, NearestNeighbors.accuracy(actual, predicted)

    # Only 1 / 2 predicted repositories was correct.
    @one.watchers << actual
    @two.watchers << predicted
    assert_equal 0.5, NearestNeighbors.accuracy(actual, predicted)

    three = Repository.new '3', 'user_c/hey', '2009-04-09'
    four = Repository.new '4', 'user_d/hmm', '2009-05-13'
    three.watchers << predicted
    four.watchers << predicted

    # Only 1 / 4 predicted repositories was correct.
    assert_equal 0.25, NearestNeighbors.accuracy(actual, predicted)

    # Now we're back to 2 / 4 predicted repositories being correct. 
    @two.watchers << actual
    assert_equal 0.5, NearestNeighbors.accuracy(actual, predicted)
  end

  def test_accuracy_positives
    actual = Watcher.new '1'
    predicted = Watcher.new '2'

    # No matches should be 0.0.
    @one.watchers << actual
    assert_equal 0.0, NearestNeighbors.accuracy(actual, predicted)

    # Only predicted 1 / 2 repositories correctly.
    @two.watchers << actual
    @two.watchers << predicted
    assert_equal 0.5, NearestNeighbors.accuracy(actual, predicted)

    three = Repository.new '3', 'user_c/hey', '2009-04-09'
    four = Repository.new '4', 'user_d/hmm', '2009-05-13'
    three.watchers << actual
    four.watchers << actual

    # Only predicted 1 / 4 repositories correctly.
    assert_equal 0.25, NearestNeighbors.accuracy(actual, predicted)

    # Now we're back to predicting 2 / 4 repositories correctly.
    @one.watchers << predicted
    assert_equal 0.5, NearestNeighbors.accuracy(actual, predicted)
  end

  private

  def ensure_symmetry(expected, one=@one, two=@two)
    assert_equal expected, NearestNeighbors.euclidian_distance(one, two)
    assert_equal expected, NearestNeighbors.euclidian_distance(two, one) 
  end  
  
end