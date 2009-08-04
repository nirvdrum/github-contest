require 'rubygems'
require 'pp'
require 'ai4r'
require 'logger'

require 'data_loader'
require 'data_exporter'
require 'ext/data_set'
require 'nearest_neighbors'

require 'logger'
$LOG = Logger.new(STDOUT)
$LOG.level = Logger::DEBUG
$LOG.datetime_format = "%Y-%m-%d %H:%M:%S"


$LOG.info "Loading data."

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

#$LOG.info "Building classifier."
#count = 0
#predictions = {}
#data_set.cross_validation(10) do |training_set, test_set|
#  $LOG.debug ">>> Starting fold #{count + 1}."
#  $LOG.debug "Training: #{Time.now.to_s} "
#  classifier = NearestNeighbors.new(training_set)
#
#  $LOG.debug "Classifying."
#  prediction = classifier.evaluation(test_set.to_test_set)
#
#  predictions[prediction] ||= []
#  predictions[prediction] << classifier
#
#  $LOG.debug "Results for fold #{count + 1}: #{NearestNeighbors.score(test_set, prediction) * 100}%"
#  count += 1
#end

$LOG.info "Training."
knn = NearestNeighbors.new(data_set)

$LOG.info "Evaluating."
evaluations = knn.evaluate(predictings)

#best_prediction = predictions.max { |x,y| x.size <=> y.size }
#classifier = best_prediction.last.first
#
#$LOG.info "Printing prediction."
#predictings.data_items.each_with_index do |predicting, i|
#  predicting << classifier.eval(predictings[i])
#end
#predictings.data_labels << 'repo_ids'
#
#$LOG.info "Accuracy: #{data_set.class_frequency(predictings.data_items.first.last) * 100}%"
#
#repo_counts = {}
#repositories.values.each do |repo|
#  repo_counts[repo.watchers.size] ||= []
#  repo_counts[repo.watchers.size] << repo
#end
#
#$LOG.debug repo_counts.keys.max
#repo_counts[repo_counts.keys.max].each {|repo| puts repo.name}
#
#$LOG.debug repositories["10"].watchers.size
#

$LOG.info "Printing results file."
File.open('results.txt', 'w') do |file|
  rails_repo = Repository.new '17'

  evaluations.each do |watcher|
    watcher.repositories << rails_repo if watcher.repositories.empty?
    $LOG.debug "Score (#{watcher.id}): #{NearestNeighbors.accuracy(knn.training_watchers[watcher.id], watcher)} -- #{watcher.to_s}"
    file.puts watcher.to_s
  end
end