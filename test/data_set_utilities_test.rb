require 'test_helper'

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

end