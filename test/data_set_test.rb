require 'test_helper'

class DataSetTest < Test::Unit::TestCase 

  def test_to_test_set

    data_labels = ['first', 'second', 'third']
    expected_data_labels = ['first', 'second']

    data_items = [
            ['1', 'abc', '3'],
            ['5', 'cdbe', '235'],
            ['6', 'aoao', '1']
    ]

    expected_data_items = [
            ['1', 'abc'],
            ['5', 'cdbe'],
            ['6', 'aoao']
    ]

    data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => data_items)
    test_set = data_set.to_test_set

    assert_equal expected_data_labels, test_set.data_labels
    assert_equal expected_data_items, test_set.data_items
  end

  def test_stratify

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

    expected_first_fold_data_items = [
            ['a', '1'],
            ['a', '2'],
            ['f', '5'],
    ]

    expected_second_fold_data_items = [
            ['b', '1'],
            ['d', '3'],
            ['q', '6'],
    ]

    expected_third_fold_data_items = [
            ['c', '1'],
            ['e', '4'],
            ['r', '7'],
    ]

    data_set = Ai4r::Data::DataSet.new(:data_items => data_items)
    data_set.stubs(:rand).returns(0) # Random data in tests is hard to test for.
    folds = data_set.stratify(3)

    assert_equal expected_first_fold_data_items, folds[0].data_items
    assert_equal expected_second_fold_data_items, folds[1].data_items
    assert_equal expected_third_fold_data_items, folds[2].data_items
  end

  def test_add_operator
    data_labels = ['blah', 'yo']

    first_data_items = [
            ['1', 'abc'],
            ['5', 'cde']
    ]

    second_data_items = [
            ['3', 'res'],
            ['7', 'aoeu']
    ]

    expected_data_items = [
            ['1', 'abc'],
            ['5', 'cde'],
            ['3', 'res'],
            ['7', 'aoeu']
    ]

    first_data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => first_data_items)
    second_data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => second_data_items)

    added_data_set = first_data_set + second_data_set

    assert_equal data_labels, added_data_set.data_labels
    assert_equal expected_data_items, added_data_set.data_items
  end

  def test_add_operator_fails_on_different_sizes
    data_labels = ['blah', 'yo']

    first_data_items = [
            ['1'],
            ['5']
    ]

    second_data_items = [
            ['3', 'res'],
            ['7', 'aoeu']
    ]

    expected_data_items = [
            ['1', 'abc'],
            ['5', 'cde'],
            ['3', 'res'],
            ['7', 'aoeu']
    ]

    first_data_set = Ai4r::Data::DataSet.new(:data_labels => ['blah'], :data_items => first_data_items)
    second_data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => second_data_items)

    assert_raise ArgumentError do
      added_data_set = first_data_set + second_data_set
    end 
  end

  def test_class_frequency

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
            ['x', '3']
    ]

    data_set = Ai4r::Data::DataSet.new(:data_items => data_items)

    assert_equal 0.3, data_set.class_frequency('1')
    assert_equal 0, data_set.class_frequency(nil)
    assert_equal 0, data_set.class_frequency('')
    assert_equal 0.1, data_set.class_frequency('6')
  end

  def test_equality
    data_labels = ['blah', 'yo']

    data_items = [
            ['1', 'abc'],
            ['5', 'cde']
    ]

    first_data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => data_items)
    second_data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => data_items)

    assert_equal first_data_set, second_data_set
  end
end