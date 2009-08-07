require 'set'

require 'neighbor_region'

class NearestNeighbors

  attr_reader :training_repositories, :training_watchers, :training_regions

  # Calculates Euclidian distance between two repositories.
  def self.euclidian_distance(first, second)
    common_watchers = first.watchers & second.watchers
    first_different_watchers = first.watchers - second.watchers
    second_different_watchers = second.watchers - first.watchers

    distance = nil

    if first == second
      return nil
    end

    if common_watchers.empty?
      nil
    else 
      distance = Math.cos((((common_watchers.size / first.watchers.size.to_f) + (common_watchers.size / second.watchers.size.to_f)) / 2.0) * (Math::PI / 2.0))
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
    
    results = {}

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

      test_regions = {}
      training_watcher.repositories.each do |repo_id|
        region = @training_regions[NeighborRegion.new(@training_repositories[repo_id]).id]

        test_regions[repo_id] = region unless region.nil?
      end

      # Calculate the distance between the representative repo for the region (i.e., the root of the hierarchy)
      # to the the most popular repo in the region.
      test_regions.each do |watched_id, region|
        distance = NearestNeighbors.euclidian_distance(@training_repositories[watched_id], region.most_popular)
    
        unless distance.nil?
          results[watcher.id][distance.to_s] ||= Set.new
          results[watcher.id][distance.to_s] << region.most_popular.id
        end
      end

      # Calculate the distance between the repository regions we know the test watcher is in, to every other
      # region in the training data.
      related_regions = {}
      test_regions.values.each do |test_region|
        training_region_count = 0
        @training_regions.values.each do |training_region|
          $LOG.debug { "Processing watcher (#{test_watcher_count}/#{test_instances.size}) - (#{training_region_count}/#{@watchers_to_regions[watcher.id].size}/#{test_regions.size})"}

          # Skip repositories that we already know the user belongs to.
          next if training_region.most_popular.watchers.include?(watcher.id)

          distance = NearestNeighbors.euclidian_distance(test_region.most_popular, training_region.most_popular)

          unless distance.nil?
            results[watcher.id][distance.to_s] ||= Set.new
            results[watcher.id][distance.to_s] << training_region.most_popular.id
          end

          training_region_count += 1
        end
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