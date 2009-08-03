require 'rubygems'
require 'pp'
require 'ai4r'

require 'data_loader'
require 'data_exporter'
require 'ext/data_set'
require 'nearest_neighbors'

puts "Loading data: #{Time.now.to_s}"

data_set = nil
if File.exists?('tmp/data_set.dump')
  File.open('tmp/data_set.dump') do |file|
    data_set = Marshal.load file
  end
else
  data_set = DataLoader.load_watchings

  File.open('tmp/data_set.dump', 'w') do |file|
    Marshal.dump data_set, file
  end
end 


#repositories = DataLoader.load_repositories
predictings = DataLoader.load_predictings

#puts "Building classifier: #{Time.now.to_s}"
#count = 0
#predictions = {}
#data_set.cross_validation(10) do |training_set, test_set|
#  puts ">>> Starting fold #{count + 1}: #{Time.now.to_s}"
#  puts "Training: #{Time.now.to_s} "
#  classifier = NearestNeighbors.new(training_set)
#
#  puts "Classifying: #{Time.now.to_s}"
#  prediction = classifier.evaluation(test_set.to_test_set)
#
#  predictions[prediction] ||= []
#  predictions[prediction] << classifier
#
#  puts "Results for fold #{count + 1}: #{NearestNeighbors.score(test_set, prediction) * 100}%"
#  count += 1
#end

puts "Training: #{Time.now.to_s}"
knn = NearestNeighbors.new(data_set)

puts "Evaluating: #{Time.now.to_s}"
evaluations = knn.evaluate(predictings)

#best_prediction = predictions.max { |x,y| x.size <=> y.size }
#classifier = best_prediction.last.first
#
#puts "Printing prediction: #{Time.now.to_s}"
#predictings.data_items.each_with_index do |predicting, i|
#  predicting << classifier.eval(predictings[i])
#end
#predictings.data_labels << 'repo_ids'
#
#puts "Accuracy: #{data_set.class_frequency(predictings.data_items.first.last) * 100}%"
#
#repo_counts = {}
#repositories.values.each do |repo|
#  repo_counts[repo.watchers.size] ||= []
#  repo_counts[repo.watchers.size] << repo
#end
#
#puts repo_counts.keys.max
#repo_counts[repo_counts.keys.max].each {|repo| puts repo.name}
#
#puts repositories["10"].watchers.size
#

puts "Printing results file: #{Time.now.to_s}"
File.open('results.txt', 'w') do |file|
  rails_repo = Repository.new '17'

  evaluations.each do |watcher|
    watcher.repositories << rails_repo if watcher.repositories.empty?
    puts "Score (#{watcher.id}): #{NearestNeighbors.accuracy(knn.training_watchers[watcher.id], watcher)} -- #{watcher.to_s}"
    file.puts watcher.to_s
  end
end