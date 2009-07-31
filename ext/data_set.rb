require 'rubygems'
require 'ai4r'
require 'enumerator'

module Ai4r
  module Data
    class DataSet

      def stratify(num_folds)
        stratified = Ai4r::Data::DataSet.new

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

    end
  end
end