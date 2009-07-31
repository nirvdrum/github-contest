require 'rubygems'
require 'ai4r'
require 'enumerator'

module Ai4r
  module Data
    class DataSet

      def stratify(num_folds)
        # Sort the data items by class so we can ensure the folds match the underlying distribution.
        sorted = data_items.sort { |x,y| x.last <=> y.last }

        # Split the sorted data into folds by grabbing every num_folds item out of the data.  This should ensure
        # that each fold matches the underlying data distribution.
        folds = []
        num_folds.times do |i|
          fold = []

          index = i + num_folds

          while index < sorted.size
            fold << sorted[index]
            index += num_folds
          end

          folds << Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => fold)
        end

        folds
      end

      # Removes the class column from all data items and the data labels.
      def to_test_set
        without_class = []

        data_items.each do |item|
          without_class << item[0...-1]
        end

        Ai4r::Data::DataSet.new(:data_labels => data_labels[0...-1], :data_items => without_class)
      end

    end
  end
end