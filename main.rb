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
$LOG.level = Logger::DEBUG
$LOG.datetime_format = "%Y-%m-%d %H:%M:%S"


$LOG.info "Loading data."

data_set = Cache.fetch('data_set') { DataLoader.load_watchings }
predictings = Cache.fetch('predictings') { DataLoader.load_predictings }
#repositories = DataLoader.load_repositories

$LOG.info "Building classifier."
count = 0
predictions = {}
#reduced_data_set = data_set.stratify(10).first
data_set.cross_validation(10) do |training_set, test_set|
  $LOG.info ">>> Starting fold #{count + 1}."
  $LOG.info ">>> Training."
  classifier = NearestNeighbors.new(training_set)

  $LOG.info ">>> Classifying."
  evaluations = classifier.evaluate(test_set.to_test_set)
  prediction = NearestNeighbors.predict(evaluations, 10)

  predictions[prediction] ||= []
  predictions[prediction] << classifier

  $LOG.info ">>> Results for fold #{count + 1}: #{NearestNeighbors.score(test_set, prediction) * 100}%"
  count += 1
  break
end

#$LOG.info "Training."
#knn = NearestNeighbors.new(data_set)
#
#$LOG.info "Evaluating."
#evaluations = knn.evaluate(predictings)
#predictions = NearestNeighbors.predict(evaluations, 10)
#
#$LOG.info "Printing results file."
#File.open('results.txt', 'w') do |file|
#  rails_repo = Repository.new '17'
#
#  predictions.each do |watcher|
#    watcher.repositories << rails_repo if watcher.repositories.empty?
#    $LOG.debug "Score (#{watcher.id}): #{NearestNeighbors.accuracy(knn.training_watchers[watcher.id], watcher)} -- #{watcher.to_s}"
#    file.puts watcher.to_s
#  end
#end