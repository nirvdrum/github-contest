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
data_set = DataLoader.load_watchings

#$LOG.info "Building classifier."
#count = 0
#predictions = {}
#reduced_data_set = data_set.stratify(10).first
#reduced_data_set.cross_validation(10) do |training_set, test_set|
#  $LOG.info ">>> Starting fold #{count + 1}."
#  $LOG.info ">>> Training."
#  classifier = NearestNeighbors.new(training_set)
#
#  $LOG.info ">>> Classifying."
#  evaluations = classifier.evaluate(test_set.to_test_set)
#  prediction = NearestNeighbors.predict(evaluations, 10)
#  all_predictions = NearestNeighbors.predict(evaluations, 1000)
#
#  predictions[prediction] ||= []
#  predictions[prediction] << classifier
#
#  test_data = test_set.to_models
#  training_data = training_set.to_models
#
#  no_region_count = 0
#  most_popular_count = 0
#  most_forked_count = 0
#  able_to_predict = 0
#  total_able_to_be_predicted = 0
#  test_data[:watchers].values.each do |test_watcher|
#    total_able_to_be_predicted += test_watcher.repositories.size
#
#    test_watcher.repositories.each do |repo_id|
#      unless training_data[:repositories][repo_id].nil?
#        able_to_predict += 1
#
#        unless classifier.training_regions[repo_id].nil?
#          most_popular_count += 1 if classifier.training_regions[repo_id].most_popular.id == repo_id
#          most_forked_count += 1 if classifier.training_regions[repo_id].most_forked.id == repo_id
#        end
#      end
#    end
#  end
#
#  $LOG.info ">>> Results for fold #{count + 1}: #{NearestNeighbors.score(test_set, prediction) * 100}% / #{NearestNeighbors.score(test_set, all_predictions) * 100}%"
#  $LOG.info ">>> Best possible prediction accuracy: #{(able_to_predict / total_able_to_be_predicted.to_f) * 100}%"
#  $LOG.info ">>> Actual repo was most popular: #{(most_popular_count / total_able_to_be_predicted.to_f) * 100}%"
#  $LOG.info ">>> Actual repo was most forked: #{(most_forked_count / total_able_to_be_predicted.to_f) * 100}%"
#
#  count += 1
#  break
#end



$LOG.info "Training."
knn = NearestNeighbors.new(data_set)

$LOG.info "Evaluating."
predictings = DataLoader.load_predictings
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