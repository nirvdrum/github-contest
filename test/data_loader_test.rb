require 'test_helper'
require 'data_loader'

class DataLoaderTest < Test::Unit::TestCase

  def test_load_watchings
    expected_data_labels = ['user_id', 'repo_id']

    expected_data_items = [
            ['1', '1234'],
            ['2', '2345'],
            ['5', '6790']
    ]

    expected_data_set = Ai4r::Data::DataSet.new(:data_labels => expected_data_labels, :data_items => expected_data_items)

    data_set = DataLoader.load_watchings('data/watchings.txt')

    assert_equal expected_data_labels, data_set.data_labels
    assert_equal expected_data_items, data_set.data_items
  end
end