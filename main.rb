require 'rubygems'
require 'pp'
require 'ai4r'
require 'logger'

require 'data_loader'
require 'data_exporter'
require 'ext/data_set'
require 'nearest_neighbors'
require 'cache'

require 'logger'
$LOG = Logger.new(STDOUT)
$LOG.level = Logger::INFO
$LOG.datetime_format = "%Y-%m-%d %H:%M:%S"


$LOG.info "Loading data."

data_set = Cache.fetch('data_set') { DataLoader.load_watchings }
predictings = Cache.fetch('predictings') { DataLoader.load_predictings }
#repositories = DataLoader.load_repositories

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
predictions = NearestNeighbors.predict(evaluations, 10)

$LOG.info "Printing results file."
File.open('results.txt', 'w') do |file|
  rails_repo = Repository.new '17'

  predictions.each do |watcher|
    watcher.repositories << rails_repo if watcher.repositories.empty?
    $LOG.debug "Score (#{watcher.id}): #{NearestNeighbors.accuracy(knn.training_watchers[watcher.id], watcher)} -- #{watcher.to_s}"
    file.puts watcher.to_s
  end
end