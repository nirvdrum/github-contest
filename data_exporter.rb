class DataExporter

  def self.export_data_set(data_set)
    ret = ''

    data_set.data_items.each do |data_item|
      ret << "#{data_item.first}:#{data_item[1..-1].join(',')}\n"
    end

    ret.strip
  end

end