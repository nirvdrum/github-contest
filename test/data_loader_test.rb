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
require 'data_loader'

class DataLoaderTest < Test::Unit::TestCase

  def test_load_watchings
    expected_data_labels = ['user_id', 'repo_id']

    expected_data_items = [
            ['1', '1234'],
            ['2', '2345'],
            ['5', '6790'],
            ['1', '2345']
    ]

    expected_data_set = Ai4r::Data::DataSet.new(:data_labels => expected_data_labels, :data_items => expected_data_items)

    data_set = DataLoader.load_watchings

    assert_equal expected_data_labels, data_set.data_labels
    assert_equal expected_data_items, data_set.data_items
  end

  def test_load_repos

    a = Repository.new '1234', 'user_a/blah', '2009-02-26'
    b = Repository.new '2345', 'user_b/yo', '2009-05-17'
    c = Repository.new '6790', 'user_c/yo', '2009-03-19'
    d = Repository.new '8324', 'user_d/hmm', '2009-04-16'

    b.parent = c

    w1 = Watcher.new('1')
    a.watchers << w1
    b.watchers << Watcher.new('2')
    b.watchers << w1
    c.watchers << Watcher.new('5')

    expected = {
            '1234' => a,
            '2345' => b,
            '6790' => c,
            '8324' => d
    }

    assert_equal expected, DataLoader.load_repositories
  end

  def test_load_predicting

    expected_data_labels = ['user_id']
    expected_data_items = [['1'], ['5']]

    data_set = DataLoader.load_predictings

    assert_equal expected_data_labels, data_set.data_labels
    assert_equal expected_data_items, data_set.data_items
  end

end