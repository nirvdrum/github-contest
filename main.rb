require 'rubygems'
require 'pp'
require 'ai4r'
require 'logger'

require 'data_loader'
require 'data_exporter'
require 'ext/data_set'
require 'nearest_neighbors'
require 'cache'

$LOG = Logger.new(STDOUT)
$LOG.level = Logger::INFO
$LOG.datetime_format = "%Y-%m-%d %H:%M:%S"


$LOG.info "Loading data."
data_set = DataLoader.load_watchings

$LOG.info "Building classifier."
count = 0
predictions = {}
#reduced_data_set = data_set.stratify(10).first
data_set.cross_validation(10) do |training_set, test_set|

  test_data = test_set.to_models
  training_data = training_set.to_models

  $LOG.info ">>> Starting fold #{count + 1}."
  $LOG.info ">>> Training."
  classifier = NearestNeighbors.new(training_set)

  $LOG.info ">>> Classifying."
  evaluations = classifier.evaluate(test_set)
  prediction = NearestNeighbors.predict(evaluations, 10)
  all_predictions = NearestNeighbors.predict(evaluations, 1000)

  predictions[prediction] ||= []
  predictions[prediction] << classifier

  no_region_count = 0
  most_popular_count = 0
  most_forked_count = 0
  able_to_predict = 0
  total_able_to_be_predicted = 0
  test_data[:watchers].values.each do |test_watcher|
    total_able_to_be_predicted += test_watcher.repositories.size

    test_watcher.repositories.each do |test_repo_id|
      unless training_data[:repositories][test_repo_id].nil?
        able_to_predict += 1

        unless classifier.training_regions[test_repo_id].nil?
          most_popular_count += 1 if classifier.training_regions[test_repo_id].most_popular.id == test_repo_id
          most_forked_count += 1 if classifier.training_regions[test_repo_id].most_forked.id == test_repo_id
        end
      end
    end
  end

  test_data[:watchers].values.each do |test_watcher|
    test_watcher.repositories.each do |test_repo_id|
      next if training_data[:repositories][test_repo_id].nil?

      if training_data[:watchers][test_watcher.id].nil?
        $LOG.info { "No training data for watcher #{test_watcher.id} -- impossible to predict" }
        next
      end

      if evaluations[test_watcher.id][test_repo_id].nil?
        $LOG.info { "Failed to find #{test_watcher.id}:#{test_repo_id}" }
      end

      training_data[:watchers][test_watcher.id].repositories.each do |training_repo_id|
      end

    end
  end

  $LOG.info ">>> Results for fold #{count + 1}: #{NearestNeighbors.score(test_set, prediction) * 100}% / #{NearestNeighbors.score(test_set, all_predictions) * 100}%"
  $LOG.info ">>> Best possible prediction accuracy: #{(able_to_predict / total_able_to_be_predicted.to_f) * 100}%"
  $LOG.info ">>> Actual repo was most popular: #{(most_popular_count / total_able_to_be_predicted.to_f) * 100}%"
  $LOG.info ">>> Actual repo was most forked: #{(most_forked_count / total_able_to_be_predicted.to_f) * 100}%"

  count += 1
  break if count == 1
end



#$LOG.info "Training."
#knn = NearestNeighbors.new(data_set)
#
#$LOG.info "Evaluating."
#predictings = DataLoader.load_predictings
#evaluations = knn.evaluate(predictings)
#predictions = NearestNeighbors.predict(evaluations, 10)
#
#repos_by_popularity = []
#sorted_regions = knn.training_regions.values.sort { |x,y| y.most_popular.watchers.size <=> x.most_popular.watchers.size }
#repos_by_popularity = sorted_regions.collect {|x| x.most_popular.id}
#
#$LOG.info "Printing results file."
#File.open('results.txt', 'w') do |file|
#
#  predictions.each do |watcher|
#    # Add the ten most popular repositories that the user is not already a watcher of to his repo list if
#    # we don't have any predictions.
#    if watcher.repositories.empty?
#      if knn.training_watchers[watcher.id].nil?
#        puts "No data for watcher: #{watcher.id}"
#        repos_by_popularity[0..10].each do |repo_id|
#          watcher.repositories << repo_id
#        end
#      else
#        added_repo_count = 0
#        repos_by_popularity.each do |suggested_repo_id|
#          unless knn.training_watchers[watcher.id].repositories.include?(suggested_repo_id)
#            watcher.repositories << suggested_repo_id
#            added_repo_count += 1
#          end
#
#          break if added_repo_count == 10
#        end
#      end
#    end
#
##    $LOG.debug "Score (#{watcher.id}): #{NearestNeighbors.accuracy(knn.training_watchers[watcher.id], watcher)} -- #{watcher.to_s}"
#    file.puts watcher.to_s
#  end
#end