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

end