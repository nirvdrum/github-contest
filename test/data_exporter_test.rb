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