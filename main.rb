require 'rubygems'
require 'pp'
require 'ai4r'

require 'data_loader'
require 'data_exporter'
require 'ext/data_set'

puts "Loading data: #{Time.now.to_s}"
data_set = DataLoader.load_watchings
repositories = DataLoader.load_repositories
predictings = DataLoader.load_predictings

puts "Building classifier: #{Time.now.to_s}"
count = 0
predictions = {}
data_set.cross_validation(10) do |training_set, test_set|
  classifier = Ai4r::Classifiers::OneR.new.build(training_set)
  prediction = classifier.eval(test_set.to_test_set)

  predictions[prediction] ||= []
  predictions[prediction] << classifier

  puts "Results for fold #{count + 1}: #{prediction}(#{repositories[prediction].name}) with #{test_set.class_frequency(prediction) * 100}%"
  count += 1
end

best_prediction = predictions.max { |x,y| x.size <=> y.size }
classifier = best_prediction.last.first

puts "Printing prediction: #{Time.now.to_s}"
predictings.data_items.each_with_index do |predicting, i|
  predicting << classifier.eval(predictings[i])
end
predictings.data_labels << 'repo_ids'

puts "Accuracy: #{data_set.class_frequency(predictings.data_items.first.last) * 100}%"

File.open('results.txt', 'w') do |file|
  file.print DataExporter.export_data_set(predictings)
end