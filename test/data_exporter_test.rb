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
require 'data_exporter'

class DataExporterTest < Test::Unit::TestCase

  def test_export_data_set

    data_labels = ['user_id', 'repo_ids']
    data_items = [
            ['1', '12'],
            ['5', '28']
    ]

    data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => data_items)

    expected = IO.readlines("#{File.dirname(__FILE__)}/data/exported.txt").join('')
    assert_equal expected, DataExporter.export_data_set(data_set)
  end

end