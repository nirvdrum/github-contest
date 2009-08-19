require 'set'
require 'neighbor_region'

class NearestNeighbors

  THREAD_POOL_SIZE = 10

  attr_reader :training_repositories, :training_watchers, :training_regions, :watchers_to_regions, :owners_to_repositories

  @@comparisons = {}

  def self.comparisons
    @@comparisons
  end

  # Calculates Euclidian distance between two repositories.
  def euclidian_distance(watcher, first, second, common_watcher_weight=1.0, related_weight=0.75, parent_child_weight=0.4, same_owner_weight=0.65)
    return nil if first == second

    common_watchers = first.watchers & second.watchers


    common_watchers_repo_diversity = common_watchers.empty? ? 1 : common_watchers.collect {|w| training_watchers[w].repositories.size}.mean
    first_common_watchers_ratio = common_watchers.size / first.watchers.size.to_f
    second_common_watchers_ratio = common_watchers.size / second.watchers.size.to_f

    #distance += (weights[0] * first_common_watchers_ratio)
    #distance += (weights[1] * second_common_watchers_ratio)
    #distance += (weights[2] * common_watchers.size)
    #distance += (weights[3] * first_different_watchers.size)
    #distance += (weights[4] * second_different_watchers.size)

    # Divide by 2 to normalize between [0, 1].
    # Multiply by Pi/2 to get half cycle of cosine function.  We only care about positive values and cosine
    # is only positive between [0, Pi/2].





    similar_watcher_counts = {}
    watcher.repositories.each do |watched_region|
      @training_repositories[watched_region].watchers.each do |related_watcher_id|
        next unless common_watchers.include?(related_watcher_id)

        similar_watcher_counts[related_watcher_id] ||= 0
        similar_watcher_counts[related_watcher_id] += 1
      end
    end

    # Convert raw counts to ratios.
    similar_watcher_counts.each do |key, value|
      similar_watcher_counts[key] = value.to_f / watcher.repositories.size
    end




          similarly_owned_count = 0
      watcher.repositories.each do |repo_id|
        repo = @training_repositories[repo_id]
	    similarly_owned_count += 1 if repo.owner == first.owner
      end
    total_watchers = @owners_to_repositories[first.owner].empty? ? 1 : @owners_to_repositories[first.owner].collect {|repo| repo.watchers.size}.sum

    lone_repo_weight = (first.parent.nil? && first.children.empty?) || (second.parent.nil? && second.children.empty?) ? 2.0 : 1.0

    if first.parent == second
      distance = lone_repo_weight * parent_child_weight * (1.0 - (common_watchers.size.to_f / [first.watchers.size, second.watchers.size].mean)) * (1.0 - ((similarly_owned_count.to_f + total_watchers) / [@owners_to_repositories[first.owner].size, 1].max)) + similar_watcher_counts.values.mean
    elsif first.related?(second)
      # Distance is the inverse of the sum of watcher count for both repositories, which has in implicit
      # bias towards the most popular repositories by watcher size.
      distance = lone_repo_weight * related_weight * (1.0 - (common_watchers.size.to_f / [first.watchers.size, second.watchers.size].mean) - ((common_watchers.size / common_watchers_repo_diversity.to_f) / [first.watchers.size, second.watchers.size].mean))
    elsif first.owner == second.owner
      distance = lone_repo_weight * same_owner_weight * (1.0 - ([common_watchers.size.to_f / first.watchers.size, common_watchers.size.to_f / second.watchers.size].mean)) * (1.0 - ((similarly_owned_count.to_f + total_watchers) / @owners_to_repositories[first.owner].size)) + similar_watcher_counts.values.mean
    else
      if common_watchers.empty?
        distance = 1000
      else
        distance = lone_repo_weight * common_watcher_weight * (1.0 - ([first_common_watchers_ratio, second_common_watchers_ratio].mean) - ((common_watchers.size / common_watchers_repo_diversity.to_f) / [first.watchers.size, second.watchers.size].mean))
      end
    end 

    @@comparisons[second.id] ||= {}
    @@comparisons[second.id][first.id] = distance

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
    actual.repositories.empty? ? 1 : (number_correct.to_f / actual.repositories.size)# - (number_incorrect.to_f / predicted.repositories.size)
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

  # Chooses the k best predictions to make from all evaluated distances.
  # Evaluations is a hash of the form {watcher_id => {repo1_id => distance1, repo2_id => distance2}}
  def self.predict(evaluations, k)
    ret = []

    evaluations.each do |user_id, distances|
      w = Watcher.new user_id

      unless distances.empty?
        #$LOG.debug { "Distances for watcher #{w.id}" }

        # Select the max(k, # scored) best distances.
        sorted_distances = distances.sort {|x, y| x.last.mean <=> y.last.mean}

        sorted_distances[0...k].each do |repo_id, distance|
          #$LOG.debug { ">>> #{key} => #{distances[key]}" }

          # TODO (KJM 8/10/09) Only add repo if distance is below some threshold.
          w.repositories << repo_id
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
    #prune_watchers
    $LOG.debug { "knn-init: Pruned training watchers: #{training_watchers.size}" }

    # Build up repository regions.
    $LOG.info "knn-init: Building repository regions."
    @training_regions = {}
    @watchers_to_regions = {}  
    @training_repositories.values.each do |repo|
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

    @owners_to_repositories = {}
    @training_repositories.values.each do |repo|
      @owners_to_repositories[repo.owner] ||= []
      @owners_to_repositories[repo.owner] << repo
    end
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
      test_watcher_count += 1
      $LOG.info { "Processing watcher (#{test_watcher_count}/#{test_instances.size}) "}
      
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

      # Calculate the distance between the repository regions we know the test watcher is in, to every other
      # region in the training data.
      #related_regions = @training_regions.values
      #related_regions = @watchers_to_regions[watcher.id]

      # Find each region we know the test watcher is in.
      test_regions = {}
      training_watcher.repositories.each do |repo_id|
        region = find_region @training_repositories[repo_id]

        test_regions[repo_id] = region unless region.nil?
      end

      repositories_to_check = Set.new
      old_size = 0

      # Find a set of repositories from fellow watchers that happen to watch a lot of same repositories as the test watcher.
      repositories_to_check.merge find_repositories_containing_fellow_watchers(test_regions)

      $LOG.info "Added repos from fellow watchers for watcher #{watcher.id} -- new size #{repositories_to_check.size} (+ #{repositories_to_check.size - old_size})"
      old_size = repositories_to_check.size

      # Add in the most popular and most forked repositories from each region we know the test watcher is in.
      test_regions.values.each do |region|
        repositories_to_check << region.most_popular.id
        repositories_to_check << region.most_forked.id
      end

      $LOG.info "Added most_popular & most_forked from test_regions for watcher #{watcher.id} -- new size #{repositories_to_check.size} (+ #{repositories_to_check.size - old_size})"
      old_size = repositories_to_check.size

      # Add in the most popular and most forked regions we know the test watcher is in.
      related_regions = find_regions_containing_fellow_watchers(test_regions)
      related_regions.each do |region|
        repositories_to_check << region.most_popular.id
        repositories_to_check << region.most_forked.id
      end

      $LOG.info "Added regions from fellow watchers for watcher #{watcher.id} -- new size #{repositories_to_check.size} (+ #{repositories_to_check.size - old_size})"
      old_size = repositories_to_check.size


      ####################################################################
      ### Handling repositories owned by owners we're already watching ###
      ####################################################################
      also_owned_counts = {}
      training_watcher.repositories.each do |repo_id|
        repo = @training_repositories[repo_id]

        also_owned_counts[repo.owner] ||= 0
        also_owned_counts[repo.owner] += 1
      end

      also_owned_counts.each do |owner, count|
        if count > 3
          repositories_to_check.merge(@owners_to_repositories[owner].collect {|r| r.id})
        end
      end   

      $LOG.info "Added similarly owned for watcher #{watcher.id} -- new size #{repositories_to_check.size} (+ #{repositories_to_check.size - old_size})"
      old_size = repositories_to_check.size


      test_region_count = 0
      test_regions.values.each do |test_region|
        thread_pool = []
        training_region_count = 0
        repositories_to_check.each do |training_repository_id|
          training_repository = @training_repositories[training_repository_id] 
          $LOG.debug { "Processing watcher (#{test_watcher_count}/#{test_instances.size}) - (#{test_region_count}/#{test_regions.size}):(#{training_region_count}/#{related_repositories.size})"}
          training_region_count += 1

          # Skip repositories that we already know the user belongs to.
          #next if training_region.most_popular.watchers.include?(watcher.id)

          unless training_repository.watchers.include?(watcher.id)
            t = Thread.new(test_region, training_repository) do |test_region, training_repository|
              distance = euclidian_distance(training_watcher, test_region.most_popular, training_repository)
              [distance, training_repository.id]
            end
            thread_pool << t

#            t2 = Thread.new do
#              distance = euclidian_distance(training_watcher, test_region.most_forked, training_repository)
#              [distance, training_repository.id]
#            end
#            thread_pool << t2
          end

          while thread_pool.size > THREAD_POOL_SIZE
            thread_pool.each do |t|
              if t.stop?
                distance, repo_id = t.value
                unless distance.nil?
                  results[watcher.id][repo_id] ||= []
                  results[watcher.id][repo_id] << distance
                end

                if watcher.repositories.include?(repo_id)
                  $LOG.debug "Found repo in global search - score: #{distance}"
                else
                  if !distance.nil?
                    $LOG.debug "Distance for bad repo: #{distance}"
                  end
                end
              end

              thread_pool.delete(t)
            end
          end
        end

        thread_pool.each do |t|
          distance, repo_id = t.value
          unless distance.nil?
            results[watcher.id][repo_id] ||= []
            results[watcher.id][repo_id] << distance
          end
        end

        test_region_count += 1
      end
    end

    results
  end

  private

  def prune_watchers
    @training_watchers.each do |user_id, watcher|
      if watcher.repositories.size > 100
        @training_watchers.delete(user_id)

        watcher.repositories.each {|repo_id| @training_repositories[repo_id].watchers.delete(user_id)}
      end
    end
  end

  def find_regions_containing_fellow_watchers(test_regions)
    # Take a look at each region the test instance is in.
    # For each region, find the most common watchers.
    @similar_watcher_counts = {}
    test_regions.values.each do |watched_region|
      watched_region.watchers.each do |related_watcher_id|
        @similar_watcher_counts[related_watcher_id] ||= 0
        @similar_watcher_counts[related_watcher_id] += 1
      end
    end

    # Convert raw counts to ratios.
    @similar_watcher_counts.each do |key, value|
      @similar_watcher_counts[key] = value.to_f / test_regions.size
    end

    # Collect the user IDs for the 10 most common watchers.
    #sorted_similar_watcher_counts = similar_watcher_counts.sort {|x, y| y.last <=> x.last}
    #most_common_watchers = sorted_similar_watcher_counts[0...5].collect {|x| x.first}

    # Collect the user IDs for any user that appears in 50% or more of the watcher's repository regions.
    most_common_watchers = @similar_watcher_counts.find_all {|key, value| value >= 0.7}.collect {|key, value| key}

    # Now go through each of those watchers and add in all the repository regions that they're watching, but
    # that the current watcher is not watching.
    thread_pool = []
    most_common_watchers.each do |common_watcher_id|
      next if @training_watchers[common_watcher_id].nil?

      t = Thread.new(common_watcher_id, test_regions) do |watcher_id, test_regions|
        local_related_regions = Set.new

        @watchers_to_regions[watcher_id].each do |region|
          local_related_regions << region unless test_regions.include?(region)
        end

        local_related_regions
      end

      thread_pool << t
    end

    related_regions = Set.new
    thread_pool.each do |t|
      related_regions.merge t.value
    end

    # Now sort the related regions by number of watchers and grab the 100 top ones.
    sorted_related_regions = related_regions.to_a.sort { |x, y| y.watchers.size <=> x.watchers.size }
    sorted_related_regions[0...100]
  end

  def find_repositories_containing_fellow_watchers(test_regions)
    # Take a look at each region the test instance is in.
    # For each region, find the most common watchers.
    @similar_watcher_counts = {}
    test_regions.values.each do |watched_region|
      watched_region.watchers.each do |related_watcher_id|
        @similar_watcher_counts[related_watcher_id] ||= 0
        @similar_watcher_counts[related_watcher_id] += 1
      end
    end

    # Convert raw counts to ratios.
    @similar_watcher_counts.each do |key, value|
      @similar_watcher_counts[key] = value.to_f / test_regions.size
    end

    # Collect the user IDs for the 10 most common watchers.
    #sorted_similar_watcher_counts = similar_watcher_counts.sort {|x, y| y.last <=> x.last}
    #most_common_watchers = sorted_similar_watcher_counts[0...5].collect {|x| x.first}

    # Collect the user IDs for any user that appears in 50% or more of the watcher's repository regions.
    most_common_watchers = @similar_watcher_counts.find_all {|key, value| value >= 0.7}.collect {|key, value| key}

    # Now go through each of those watchers and add in all the repositories that they're watching, but
    # that the current watcher is not watching.
    related_repositories = {}
    most_common_watchers.each do |common_watcher_id|
      next if @training_watchers[common_watcher_id].nil?

      @training_watchers[common_watcher_id].repositories.each do |repo|
        related_repositories[repo] ||= 0
        related_repositories[repo] += 1
      end
    end

    # Now sort the related regions by number of watchers and grab the 10 top ones.
    sorted_related_repositories = related_repositories.to_a.sort { |x, y| y.last <=> x.last }
    sorted_related_repositories[0...100].collect {|x| x.first}
  end

  def find_region(repo)
    repo_root = Repository.find_root repo
    @training_regions[repo_root.id]
  end

end