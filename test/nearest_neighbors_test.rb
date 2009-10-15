# Copyright 2009 Kevin J. Menard Jr.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'test_helper'
require 'repository'
require 'nearest_neighbors'
require 'watcher'
require 'data_loader'

class NearestNeighborsTest < Test::Unit::TestCase

  def setup
    @one = Repository.new '1234', 'user_a/yo', '2009-02-26'
    @two = Repository.new '4567', 'user_b/blah', '2009-03-17'

    Cache.clear
  end

  def test_euclidian_distance_no_match
    ensure_symmetry(nil)
  end

  def test_euclidian_distance_by_watchers
    w1 = Watcher.new '1'
    w2 = Watcher.new '2'
    w3 = Watcher.new '3'

    # No matches.
    @one.watchers << w1
    ensure_symmetry(nil)

    # Exact match.
    @two.watchers << w1
    ensure_symmetry(Math.cos(Math::PI / 2.0))
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

    ensure_symmetry(Math.cos(0.75 * (Math::PI / 2.0)), @one, @two)
    ensure_symmetry(Math.cos((((1.0 / 1.0) + (1.0 / 5.0)) / 2.0) * (Math::PI / 2.0)), @one, three)
  end

  def test_euclidian_distance_by_ancestry
    @one.parent = @two

    # No watchers, so baseline score is 1.0.
    ensure_symmetry(1.0)

    w1 = Watcher.new '1'
    w2 = Watcher.new '2'

    @one.associate w1
    @two.associate w2

    # Naive scoring is the inverse of the sum of watcher count for both repositories.  
    ensure_symmetry(0.5)
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
    @one.associate predicted
    assert_equal -1.0, NearestNeighbors.accuracy(actual, predicted)

    # Only 1 / 2 predicted repositories was correct.
    @one.associate actual
    @two.associate predicted
    assert_equal 0.5, NearestNeighbors.accuracy(actual, predicted)

    three = Repository.new '3', 'user_c/hey', '2009-04-09'
    four = Repository.new '4', 'user_d/hmm', '2009-05-13'
    three.associate predicted
    four.associate predicted

    # Only 1 / 4 predicted repositories was correct.
    assert_equal 0.25, NearestNeighbors.accuracy(actual, predicted)

    # Now we're back to 2 / 4 predicted repositories being correct. 
    @two.associate actual
    assert_equal 0.5, NearestNeighbors.accuracy(actual, predicted)
  end

  def test_accuracy_positives
    actual = Watcher.new '1'
    predicted = Watcher.new '2'

    # No matches should be 0.0.
    @one.associate actual
    assert_equal 0.0, NearestNeighbors.accuracy(actual, predicted)

    # Only predicted 1 / 2 repositories correctly.
    @two.associate actual
    @two.associate predicted
    assert_equal 0.5, NearestNeighbors.accuracy(actual, predicted)

    three = Repository.new '3', 'user_c/hey', '2009-04-09'
    four = Repository.new '4', 'user_d/hmm', '2009-05-13'
    three.associate actual
    four.associate actual

    # Only predicted 1 / 4 repositories correctly.
    assert_equal 0.25, NearestNeighbors.accuracy(actual, predicted)

    # Now we're back to predicting 2 / 4 repositories correctly.
    @one.associate predicted
    assert_equal 0.5, NearestNeighbors.accuracy(actual, predicted)
  end

  def test_initialize
    training_set = DataLoader.load_watchings

    knn = NearestNeighbors.new(training_set)

    r1 = Repository.new '1234'
    r2 = Repository.new '2345'
    r3 = Repository.new '6790'

    r2.parent = r3

    w1 = Watcher.new '1'
    w2 = Watcher.new '2'
    w3 = Watcher.new '5'

    r1.watchers << w1
    r2.watchers << w1
    r2.watchers << w2
    r3.watchers << w3

    repositories = { r1.id => r1, r2.id => r2, r3.id => r3 }  

    expected = training_set.to_models
    assert_equal expected[:watchers], knn.training_watchers
    assert_equal expected[:repositories], knn.training_repositories
    assert_equal ['1234', '6790'], knn.training_regions.keys
  end

  def test_evaluate
    fold1_items = [
            ['1', '2345'],
            ['2', '2345'],
            ['2', '6790']
    ]
    fold1 = Ai4r::Data::DataSet.new(:data_items => fold1_items)

    fold2_items = [
            ['1', '6790'],
            ['5', '6790'],
            ['3', '6790'],
            ['1', '1234'],
            ['5', '8324']
    ]
    fold2 = Ai4r::Data::DataSet.new(:data_items => fold2_items)

    data_set = fold1 + fold2
    data_set.stubs(:stratify).with(2).returns([fold1, fold2])

    expected = [
            {
                    '1' => {'8324' => 0.5},
                    '2' => {}
            },
            {
                    '1' => {},
                    '5' => {},
                    '3' => {}
            }
    ]

    count = 0
    data_set.cross_validation(2) do |training_set, test_set|
      knn = NearestNeighbors.new(training_set)

      evaluation = knn.evaluate(test_set)

      assert_equal expected[count], evaluation, "Comparison failed for count #{count}"

      count += 1
    end
  end

  def test_score
    test1_items = [
            ['1', '2345'],
            ['2', '2345'],
            ['2', '6790']
    ]
    test_set1 = Ai4r::Data::DataSet.new(:data_items => test1_items)

    test2_items = [
            ['1', '6790'],
            ['5', '6790'],
            ['1', '1234']
    ]
    test_set2 = Ai4r::Data::DataSet.new(:data_items => test2_items)

    w = Watcher.new('1')
    repo = Repository.new '6790'
    w.associate repo
    recommendations = [[], [w]]

    # Predicted 0 / 3 accurately.
    assert_equal 0.0, NearestNeighbors.score(test_set1, recommendations[0])

    # Predicted 1 / 3 accurately.
    assert_equal 1.0 / 3.0, NearestNeighbors.score(test_set2, recommendations[1])
  end

  def test_prune_watchers
    training_set = DataLoader.load_watchings
    knn = NearestNeighbors.new(training_set)

    # Stub out a watcher to prune.
    to_prune = knn.training_watchers.first.last
    repo = to_prune.repositories.first
    to_prune.stubs(:repositories).returns([repo] * 101)

    knn.send :prune_watchers

    assert_nil knn.training_watchers[to_prune.id]
  end

  def test_predictions
    r1 = Repository.new '1234'
    r2 = Repository.new '2345'
    r3 = Repository.new '6790'

    evaluations = {
            '1' => {r2 => 0.2, r3 => 1.0, r1 => 0.7},
            '5' => {r1 => 0.5},
            '2' => {}
    }


    w1 = Watcher.new '1'
    w2 = Watcher.new '2'
    w3 = Watcher.new '5'

    # w1 will only have the two lowest repository distances because we're setting k=2.
    w1.repositories << Repository.new(r2.id)
    w1.repositories << Repository.new(r1.id)

    w3.repositories << Repository.new(r1.id)

    # Test the predictions for the k=2 nearest neighbors.
    actual = NearestNeighbors.predict(evaluations, 2)
    assert_equal [w1, w2, w3], actual

    assert_equal w1.repositories, actual[0].repositories
    assert_equal w2.repositories, actual[1].repositories
    assert_equal w3.repositories, actual[2].repositories
  end
  
  private

  def ensure_symmetry(expected, one=@one, two=@two)
    assert_equal expected, NearestNeighbors.euclidian_distance(one, two)
    assert_equal expected, NearestNeighbors.euclidian_distance(two, one) 
  end  
  
end