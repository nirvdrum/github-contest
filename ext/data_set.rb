require 'rubygems'
require 'ai4r'
require 'enumerator'
require 'memoize'

require 'data_set_utilities'

module Ai4r
  module Data
    class DataSet

      include Memoize
      include DataSetUtilities

      alias :old_initialize :initialize
      def initialize(*args)
        old_initialize *args

        memoize :to_models
      end

      def stratify(num_folds)
        # Although the data will ultimately be sorted by class value, the entries within that class value should be
        # randomized to start.  Otherwise, stratification will always lead to the same resulting folds.
        randomized = data_items #.sort_by { rand }

        # Sort the data items by class so we can ensure the folds match the underlying distribution.
        sorted = randomized.sort { |x,y| x.last <=> y.last }

        # Split the sorted data into folds by grabbing every num_folds item out of the data.  This should ensure
        # that each fold matches the underlying data distribution.
        folds = []
        num_folds.times do |i|
          fold = []

          index = i

          while index < sorted.size
            fold << sorted[index]
            index += num_folds
          end

          # Randomize the data again to guard against classifiers that are prone to choosing the first
          # sample drawn from the data set.
          folds << Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => fold)#.sort_by { rand })
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

      def +(other)
        added_data_items = data_items + other.data_items

        ret = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => added_data_items)
      end

      def class_frequency(value)
        count = 0

        data_items.each do |data_item|
          count += 1 if data_item.last == value
        end

        count / data_items.size.to_f
      end

      def ==(other)
        return false if other.nil?

        data_labels == other.data_labels &&
        data_items == other.data_items    
      end
    end
  end
end