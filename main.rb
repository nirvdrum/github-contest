require 'rubygems'
require 'pp'
require 'ai4r'
require 'logger'

require 'data_loader'
require 'data_exporter'
require 'ext/data_set'
require 'nearest_neighbors'
require 'cache'


require 'irb'

module IRB # :nodoc:
  def self.start_session(binding)
    unless @__initialized
      args = ARGV
      ARGV.replace(ARGV.dup)
      IRB.setup(nil)
      ARGV.replace(args)
      @__initialized = true
    end

    workspace = WorkSpace.new(binding)

    irb = Irb.new(workspace)

    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context

    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end
end

class Array
  def sum
    inject(0.0) { |sum, e| sum + e }
  end

  def mean
    length == 0 ? 0 : sum / length
  end
end

def analyze(test_data, training_data, prediction, all_predictions, classifier, evaluations)
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
      next if evaluations[test_watcher.id].nil?

      if training_data[:watchers][test_watcher.id].nil?
        $LOG.info { "No training data for watcher #{test_watcher.id} -- impossible to predict" }
        next
      end

      if evaluations[test_watcher.id][test_repo_id].nil? && !training_data[:repositories][test_repo_id].nil?
        $LOG.info { "Failed to find #{test_watcher.id}:#{test_repo_id}" }
      end
    end
  end

  prediction.each do |p|
    p.repositories.each do |repo|
      if !test_data[:watchers][p.id].repositories.include?(repo)
        $LOG.info "Bad prediction #{p.id}:#{repo} with distance #{evaluations[p.id][repo].mean}"
      end
    end

    unless training_data[:watchers][p.id].nil?
      test_data[:watchers][p.id].repositories.delete_if {|r| training_data[:repositories][r].nil?}
      $LOG.info "Accuracy for watcher #{p.id}: #{NearestNeighbors.accuracy(test_data[:watchers][p.id], p) * 100}%"
    end 
  end

  all_predictions.each_with_index do |p, i|
    p.repositories.each do |repo|
      if test_data[:watchers][p.id].repositories.include?(repo) && !prediction[i].repositories.include?(repo)
        $LOG.info "Missing prediction #{p.id}:#{repo} with distance #{evaluations[p.id][repo].mean}"
      end
    end
  end

  has_parent_count = 0
  has_children_count = 0
  same_owner_count = 0
  total_repo_count = 0
  test_data[:watchers].values.each do |test_watcher|
    next if test_watcher.nil?

    test_watcher.repositories.each do |test_repo_id|
      total_repo_count += 1
      next if training_data[:repositories][test_repo_id].nil?

      has_parent_count += 1 unless training_data[:repositories][test_repo_id].parent.nil?
      has_children_count += 1 unless training_data[:repositories][test_repo_id].children.empty?

      unless training_data[:watchers][test_watcher.id].nil?
        training_data[:watchers][test_watcher.id].repositories.each do |training_repo_id|
          same_owner_count += 1 if training_data[:repositories][training_repo_id].owner == training_data[:repositories][test_repo_id].owner
        end
      end 

    end
  end

  $LOG.info "Has parent ratio: #{(has_parent_count / total_repo_count.to_f) * 100}%"
  $LOG.info "Has children ratio: #{(has_children_count / total_repo_count.to_f) * 100}%"
  $LOG.info "Same owner ratio: #{(same_owner_count / total_repo_count.to_f) * 100}%"

  $LOG.info ">>> Best possible prediction accuracy: #{(able_to_predict / total_able_to_be_predicted.to_f) * 100}%"
  $LOG.info ">>> Actual repo was most popular: #{(most_popular_count / total_able_to_be_predicted.to_f) * 100}%"
  $LOG.info ">>> Actual repo was most forked: #{(most_forked_count / total_able_to_be_predicted.to_f) * 100}%"
end



$LOG = Logger.new(STDOUT)
$LOG.level = Logger::INFO
$LOG.datetime_format = "%Y-%m-%d %H:%M:%S"


$LOG.info "Loading data."
data_set = DataLoader.load_watchings

$LOG.info "Building classifier."
count = 0
predictions = {}
data_set.cross_validation(10) do |training_set, large_test_set|

  reduced_data_set = large_test_set.stratify(100).each do |test_set|

  test_data = test_set.to_models
  training_data = training_set.to_models

  $LOG.info ">>> Starting fold #{count + 1}."
  $LOG.info ">>> Training."
  knn = NearestNeighbors.new(training_set)

  $LOG.info ">>> Classifying."
  #test_set = Ai4r::Data::DataSet.new(:data_items => [['83']])
  evaluations = knn.evaluate(test_set)
  prediction = NearestNeighbors.predict(evaluations, 10)
  all_predictions = NearestNeighbors.predict(evaluations, 10000)

  predictions[prediction] ||= []
  predictions[prediction] << knn

  analyze(test_data, training_data, prediction, all_predictions, knn, evaluations)

  $LOG.info ">>> Results for fold #{count + 1}: #{NearestNeighbors.score(test_set, prediction) * 100}% / #{NearestNeighbors.score(test_set, all_predictions) * 100}%"

  IRB.start_session(binding) 

  count += 1
    break
  end
  break
end






#
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



