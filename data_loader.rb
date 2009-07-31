require 'rubygems'
require 'ai4r'

class DataLoader
  def self.load_watchings(data_file='data/data.txt')
    data_labels = ['user_id', 'repo_id']
    data_items = []

    IO.foreach(data_file) do |line|
      data_items << line.strip.split(':')
    end

    data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => data_items)
    data_set
  end
end