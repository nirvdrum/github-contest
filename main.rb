require 'rubygems'
require 'pp'
require 'ai4r'

require 'data_loader'
require 'ext/data_set'

puts "Loading data: #{Time.now.to_s}"
data_set = DataLoader.load_watchings
repositories = DataLoader.load_repositories
predictings = DataLoader.load_predictings

puts "Creating data folds: #{Time.now.to_s}"
folds = data_set.stratify(10)

puts "Building classifier: #{Time.now.to_s}"
zeror = Ai4r::Classifiers::ZeroR.new.build(data_set)

puts "Printing prediction: #{Time.now.to_s}"

pp predictings.data_items
predictings.data_items.each_with_index do |predicting, i|
  predicting << zeror.eval(predicting[i])
end
predictings.data_labels << 'repo_ids'

pp predictings