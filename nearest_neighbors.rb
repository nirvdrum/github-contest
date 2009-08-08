require 'set'

require 'neighbor_region'

class NearestNeighbors

  attr_reader :training_repositories, :training_watchers, :training_regions

  # Calculates Euclidian distance between two repositories.
  def self.euclidian_distance(first, second)
    return nil if first == second

    weights = [1.0, 1.0, 1.0, 1.0, 1.0]

    common_watchers = first.watchers & second.watchers
    first_different_watchers = first.watchers - second.watchers
    second_different_watchers = second.watchers - first.watchers

    distance = 0

    first_common_watchers_ratio = common_watchers.size / first.watchers.size.to_f
    second_common_watchers_ratio = common_watchers.size / second.watchers.size.to_f

    distance += (weights[0] * first_common_watchers_ratio)
    distance += (weights[1] * second_common_watchers_ratio)
    distance += (weights[2] * common_watchers.size)
    distance += (weights[3] * first_different_watchers.size)
    distance += (weights[4] * second_different_watchers.size)

    # Divide by 2 to normalize between [0, 1].
    # Multiply by Pi/2 to get half cycle of cosine function.  We only care about positive values and cosine
    # is only positive between [0, Pi/2].
    #distance += Math.cos(((first_common_watchers_ratio + second_common_watchers_ratio) / 2.0) * (Math::PI / 2.0))

        
    if first.related? second
      # Distance is the inverse of the sum of watcher count for both repositories, which has in implicit
      # bias towards the most popular repositories by watcher size.
      #distance += (1.0 / [first.watchers.size + second.watchers.size, 1.0].max)
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
  def self.score(test_set, predictions)
    models = test_set.to_models
    watchers = models[:watchers]

    number_correct = 0.0

    # Look at each predicted answer for each watcher.  If the prediction appears in the watcher's list, then it
    # was an accurate prediction.  Otherwise, no score awarded.
    predictions.each do |prediction|
      #$LOG.info "Scoring user #{user_id}"
      watcher = watchers[prediction.id]

      if watcher.nil?
        $LOG.error "Got a nil user in evaluations for user id #{watcher.id}"
        next
      end

      prediction.repositories.each do |repo_id|
        #if watcher.repositories.include? repo_id
        #  $LOG.info ">>> WOO HOO!!!! Distance for correct repo: #{distance}"

        #  if distance == Float::MAX
        #    $LOG.info ">>>>>> Bad heuristic linking #{repo_id}"
        #  end
        #end

        number_correct += 1 if watcher.repositories.include?(repo_id)
      end

      #no_distances = watcher.repositories - distances.values
      #no_distances.each do |repo_id|
      #  $LOG.info ">*>* No distance found for #{no_distances.size} repositories"
      #end
    end

    total_repositories_to_predict = watchers.values.inject(0) { |sum, watcher| sum + watcher.repositories.size }

    number_correct / total_repositories_to_predict.to_f
  end

  def self.predict(evaluations, k)
    ret = []

    evaluations.each do |user_id, distances|
      w = Watcher.new user_id

      unless distances.empty?
        $LOG.debug { "Distances for watcher #{w.id}" }

        # Select the max(k, # scored) best distances.
        sorted_distances = distances.keys.sort {|x, y| x.to_f <=> y.to_f}
        upper_bound = [k, sorted_distances.size].min

        sorted_distances[0...upper_bound].each do |key|
          $LOG.debug { ">>> #{key} => #{distances[key]}" }

          distances[key].each do |repo_id|
            w.repositories << repo_id
          end
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

    # Build up repository regions.
    $LOG.info "knn-init: Building repository regions."
    @training_regions = {}
    @watchers_to_regions = {}
    @training_repositories.each do |repo_id, repo|
      repo_root = Repository.find_root repo

      existing_region = @training_regions[repo_root.id]
      if existing_region.nil?
        @training_regions[repo_root.id] = NeighborRegion.new repo
      else
        existing_region.repositories << repo
      end

      # Store repo in inverted list structure from watcher_id to regions.
      repo.watchers.each do |watcher_id|
        @watchers_to_regions[watcher_id] ||= Set.new
        @watchers_to_regions[watcher_id] << @training_regions[repo_root.id]
      end
    end
    $LOG.debug { "knn-init: Total regions: #{@training_regions.size}" }
  end

  def evaluate(test_set)
    $LOG.info "knn-evaluate: Loading watchers."
    
    # Build up a list of watcher objects from the test set.
    models = test_set.to_models
    test_instances = models[:watchers]
    $LOG.info { "knn-evaluate: Total unique test watchers: #{test_instances.size}" }
    
    results = {}

    # Prune out regions with small number of watchers.
    #related_regions = {}
    #@training_regions.each do |region_id, region|
    #  related_regions[region_id] = region if region.watchers.size > 10
    #end

    # For each watcher in the test set . . .
    $LOG.info "knn-evaluate: Starting evaluations."
    test_watcher_count = 0
    test_instances.values.each do |watcher|
      results[watcher.id] = {}

      # See if we have any training instances for the watcher.  If not, we really can't guess anything.
      training_watcher = @training_watchers[watcher.id]
      if training_watcher.nil?
        # $LOG.warn "No training instances for watcher #{watcher.id}"
        next
      end


      ###################################
      ### Handling repository regions ###
      ###################################

      # Extract the regions we know the test watcher belongs to.
      test_regions = {}
      training_watcher.repositories.each do |repo_id|
        region = @training_regions[NeighborRegion.new(@training_repositories[repo_id]).id]

        test_regions[repo_id] = region unless region.nil?
      end

      # Calculate the distance between the representative repo for the region (i.e., the root of the hierarchy)
      # to the the most popular and most forked repos in the region.
      test_regions.each do |watched_id, region|
        popular_distance = NearestNeighbors.euclidian_distance(@training_repositories[watched_id], region.most_popular)  
        unless popular_distance.nil?
          results[watcher.id][popular_distance.to_s] ||= Set.new
          results[watcher.id][popular_distance.to_s] << region.most_popular.id
        end

        forked_distance = NearestNeighbors.euclidian_distance(@training_repositories[watched_id], region.most_forked)
        unless forked_distance.nil?
          results[watcher.id][forked_distance.to_s] ||= Set.new
          results[watcher.id][forked_distance.to_s] << region.most_forked.id
        end
      end

      # Calculate the distance between the repository regions we know the test watcher is in, to every other
      # region in the training data.
      related_regions = @training_regions.values #@watchers_to_regions[watcher.id]
      test_region_count = 0
      test_regions.values.each do |test_region|
        training_region_count = 0
        related_regions.each do |training_region|
          $LOG.debug { "Processing watcher (#{test_watcher_count}/#{test_instances.size}) - (#{test_region_count}/#{test_regions.size}):(#{training_region_count}/#{related_regions.size})"}
          training_region_count += 1

          # Skip repositories that we already know the user belongs to.
          next if training_region.most_popular.watchers.include?(watcher.id)

          popular_distance = NearestNeighbors.euclidian_distance(test_region.most_popular, training_region.most_popular)
          unless popular_distance.nil?
            results[watcher.id][popular_distance.to_s] ||= Set.new
            results[watcher.id][popular_distance.to_s] << training_region.most_popular.id
          end

          forked_distance = NearestNeighbors.euclidian_distance(test_region.most_popular, training_region.most_forked)
          unless forked_distance.nil?
            results[watcher.id][forked_distance.to_s] ||= Set.new
            results[watcher.id][forked_distance.to_s] << training_region.most_forked.id
          end
        end

        test_region_count += 1
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