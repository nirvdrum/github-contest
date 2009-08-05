require 'set'

class NearestNeighbors

  attr_reader :training_repositories, :training_watchers

  # Calculates Euclidian distance between two repositories.
  def self.euclidian_distance(first, second)
    common_watchers = first.watchers & second.watchers
    first_different_watchers = first.watchers - second.watchers
    second_different_watchers = second.watchers - first.watchers

    distance = Float::MAX

    if first_different_watchers.empty? && second_different_watchers.empty?
      distance = 0.0
    else 
      distance = 1.0 / [first_different_watchers.size, second_different_watchers.size].max
    end

    if first.related? second
      # Distance is the inverse of the sum of watcher count for both repositories, which has in implicit
      # bias towards the most popular repositories by watcher size.
      distance = 1.0 / [first.watchers.size + second.watchers.size, 1.0].max
    end

    distance
    
    # Other factors for calculating distance:
    # - Ages of repositories
    # - Ancestry of two repositories (give higher weight if one of the repositories is the most popular by watchings and/or forks)
    # - # of forks
    # - watcher chains (e.g., repo a has watchers <2, 5>, repo b has watchers <5, 7>, repo c has watchers <7> . . . a & c may be slightly related.
    # - Language overlaps
    # - Size of repositories?

    # Also, look at weighting different attributes.  Maybe use GA to optimize.
  end

  # Calculates accuracy between actual and predicted watchers.
  def self.accuracy(actual, predicted)
    return -1.0 if actual.nil? || predicted.nil?
    return 1.0 if actual.repositories.empty? && predicted.repositories.empty?
    return -1.0 if actual.repositories.empty? && !predicted.repositories.empty?
    return 0.0 if actual.repositories.empty? || predicted.repositories.empty?

    number_correct = (actual.repositories & predicted.repositories).size
    number_incorrect = (predicted.repositories - actual.repositories).size

    # Rate the accuracy of the predictions, with a bias towards positive results.
    (number_correct.to_f / actual.repositories.size) - (number_incorrect.to_f / predicted.repositories.size)
  end

  # Aggregates accuracies of evaluations of each item in the test set, yielding an overall accuracy score.
  def self.score(test_set, evaluations)
    models = test_set.to_models
    watchers = models[:watchers]

    number_correct = 0.0

    # Look at each predicted answer for each watcher.  If the prediction appears in the watcher's list, then it
    # was an accurate prediction.  Otherwise, no score awarded.
    evaluations.each do |user_id, distances|
      #$LOG.info "Scoring user #{user_id}"
      watcher = watchers[user_id]

      if watcher.nil?
        $LOG.error "Got a nil user in evaluations for user id #{user_id}"
        next
      end

      distances.each do |distance, repo_id|
        if watcher.repositories.include? repo_id
          $LOG.info ">>> WOO HOO!!!! Distance for correct repo: #{distance}"
        end
        
        number_correct += 1 if watcher.repositories.include?(repo_id)
      end

      #no_distances = watcher.repositories - distances.values
      #no_distances.each do |repo_id|
      #  $LOG.info ">*>* No distance found for #{no_distances.size} repositories"
      #end
    end

    total_repositories_to_predict = watchers.values.inject(0) { |sum, watcher| sum + watcher.repositories.size }

    number_correct / total_repositories_to_predict
  end

  def self.predict(evaluations, k)
    ret = []

    evaluations.each do |user_id, distances|
      w = Watcher.new user_id

      unless distances.empty?
        sorted_distances = distances.keys.sort {|x, y| y <=> x}
        upper_bound = [k, sorted_distances.size].min

        $LOG.debug { "Distances for watcher #{w.id}" }

        sorted_distances[0...upper_bound].each do |key|
          $LOG.debug { ">>> #{key} => #{distances[key]}" }

          w.repositories << Repository.new(distances[key])
        end
      end

      ret << w
    end

    ret
  end

  def initialize(training_set)
    $LOG.info "knn-init: Loading watchers and repositories."

    models = training_set.to_models
    @training_watchers = models[:watchers]
    @training_repositories = models[:repositories]

    $LOG.debug { "knn-init: Unique training users: #{@training_watchers.size}" }
    $LOG.debug { "knn-init: Unique training repositories: #{training_repositories.size}" }

    # Watchers watching a lot of repositories are not the norm.
    $LOG.info "knn-init: Pruning watchers."
    prune_watchers
    $LOG.debug { "knn-init: Pruned training watchers: #{training_watchers.size}" }
  end

  def evaluate(test_set)
    $LOG.info "knn-evaluate: Loading watchers."
    # Build up a list of watcher objects from the test set.
    models = test_set.to_models
    test_instances = models[:watchers]
    
    results = {}

    # For each watcher in the test set . . .
    $LOG.info "knn-evaluate: Starting evaluations."
    test_watcher_count = 0
    test_instances.values.each do |watcher|
      results[watcher.id] = {}

      # See if we have any training instances for the watcher.  If not, we really can't guess anything.
      training_watcher = @training_watchers[watcher.id]
      next if training_watcher.nil?

      # For each observed repository in the training data . . .
      watcher_repo_progress = 0
      training_watcher.repositories.each do |training_repo_id|

        # Build up a set of repositories to compare against.
        to_check = Set.new
        if @training_repositories[training_repo_id].watchers.size < 100
          @training_repositories[training_repo_id].watchers.each do |training_repo_watcher_id|
            next if training_repo_watcher_id == training_watcher.id

            unless @training_watchers[training_repo_watcher_id].nil?
              @training_watchers[training_repo_watcher_id].repositories.each do |repo|
                to_check += [repo]
              end
            end
          end
        end

        if to_check.size > 1000
          $LOG.info { "knn-evaluate: Large to_check for test watcher #{watcher.id} on repo #{@training_repositories[training_repo_id].name} with #{@training_repositories[training_repo_id].watchers.size} watchers" }
        end

        $LOG.debug { "knn-evaluate: Processing watcher #{watcher.id} (#{test_watcher_count + 1}/#{test_instances.size})-(#{watcher_repo_progress + 1}/#{watcher.repositories.size}:#{to_check.size})" }

        # Compare against all other repositories to calculate the Euclidean distance between them.
        training_repo_progress = 0
        to_check.each do |check_repo_id|
         # $LOG.debug "Processing #{watcher_repo_progress + 1} / #{watcher.repositories.size} - #{training_repo_progress + 1} / #{@training_repositories.size}"
          training_repo_progress += 1

          # Skip over repositories we already know the watcher belongs to.     
          next if @training_repositories[check_repo_id].watchers.include?(watcher.id)

          # Calculate the distance, culling for absolute non-matches (i.e., distance == Float::MAX)
          distance = NearestNeighbors.euclidian_distance(@training_repositories[check_repo_id], @training_repositories[check_repo_id])

          results[watcher.id][distance] = check_repo_id unless distance == Float::MAX
        end

        watcher_repo_progress += 1
      end

      test_watcher_count += 1
    end

    results
  end

  private

  def distance_cache_key(first, second)
    "#{[first.id, second.id].min}_#{[first.id, second.id].max}"
  end

  def prune_watchers
    @training_watchers.each do |user_id, watcher|
      if watcher.repositories.size > 100
        @training_watchers.delete(user_id)

        watcher.repositories.each {|repo_id| @training_repositories[repo_id].watchers.delete(user_id)}
      end
    end
  end
end