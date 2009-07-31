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

  def test_load_repos

    a = Repository.new 'user_a/blah', '2009-02-26'
    b = Repository.new 'user_b/yo', '2009-05-17'
    c = Repository.new 'user_c/yo', '2009-03-19'

    b.parent = c

    expected = {
            '1234' => a,
            '2345' => b,
            '6790' => c
    }

    assert_equal expected, DataLoader.load_repositories('data/repos.txt')
  end

  def test_load_predicting

    expected_data_labels = ['user_id']
    expected_data_items = [['1'], ['5']]

    data_set = DataLoader.load_predictings('data/predictings.txt')

    assert_equal expected_data_labels, data_set.data_labels
    assert_equal expected_data_items, data_set.data_items
  end

end