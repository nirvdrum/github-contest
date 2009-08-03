class NearestNeighbors

  attr_reader :training_repositories, :training_watchers

  # Calculates Euclidian distance between two repositories.
  def self.euclidian_distance(first, second)
    common_watchers = first.watchers & second.watchers
    first_different_watchers = first.watchers - second.watchers
    second_different_watchers = second.watchers - first.watchers

    if common_watchers.empty?
      Float::MAX
    elsif first_different_watchers.empty? && second_different_watchers.empty?
      0.0
    else 
      1.0 / [first_different_watchers.size, second_different_watchers.size].max
    end

    # Other factors for calculating distance:
    # - Ages of repositories
    # - Ancestry of two repositories (give higher weight if one of the repositories is the most popular by watchings and/or forks)
    # - # of forks
    # - watcher chains (e.g., repo a has watchers <2, 5>, repo b has watchers <5, 7>, repo c has watchers <7> . . . a & c may be slightly related.

    # Also, look at weighting different attributes.  Maybe use GA to optimize.
  end

  # Calculates accuracy between actual and predicted watchers.
  def self.accuracy(actual, predicted)
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
    watchers = Watcher.from_data_set test_set

    number_correct = 0.0

    # Look at each predicted answer for each watcher.  If the prediction appears in the watcher's list, then it
    # was an accurate prediction.  Otherwise, no score awarded.
    evaluations.each do |user_id, scores|
      scores.each do |score, repo|
        number_correct += 1 if watchers[user_id].repositories.include?(repo)
      end
    end

    total_repositories_to_predict = watchers.values.inject(0) { |sum, watcher| sum + watcher.repositories.size }

    number_correct / total_repositories_to_predict
  end

  def initialize(training_set)
    puts "knn-init: Loading watchers: #{Time.now.to_s}"

    @training_watchers = Watcher.from_data_set training_set, 'knn_training'

    puts "knn-init: Unique training users: #{@training_watchers.size}"

    @training_repositories = {}

    puts "knn-init: Loading repositories: #{Time.now.to_s}"
    @training_watchers.values.each do |watcher|
      watcher.repositories.each do |repo|
        @training_repositories[repo.id] ||= repo
      end
    end
    puts "knn-init: Unique training repositories: #{training_repositories.size}"

    # Watchers watching a lot of repositories are not the norm.
    puts "knn-init: Pruning watchers: #{Time.now.to_s}"
    @training_watchers.each do |user_id, watcher|
      if watcher.repositories.size > 100
        @training_watchers.delete(user_id)

        watcher.repositories.each {|repo| repo.watchers.delete(watcher)}
      end 
    end
    puts "knn-init: Pruned training watchers: #{training_watchers.size}"

    # Repositories with only one watcher are not very useful.
    puts "knn-init: Pruning repositories: #{Time.now.to_s}"
    @training_repositories.each do |repo_id, repo|
      if repo.watchers.size == 1
        @training_repositories.delete(repo_id)

        repo.watchers.each {|watcher| watcher.repositories.delete(repo)}
      end 
    end
    puts "knn-init: Pruned training repositories: #{training_repositories.size}"
  end

  def evaluate(test_set)
    puts "knn-evaluate: Loading watchers: #{Time.now.to_s}"
    # Build up a list of watcher objects from the test set.
    @test_instances = Watcher.from_data_set test_set

    results = {}

    count = 0
    # For each watcher in the test set . . .
    @test_instances.each do |user_id, watcher|
      results[user_id] = {}

      puts "knn-evaluate: Processing watcher #{user_id} (#{count + 1} / #{@test_instances.size}): #{Time.now.to_s}"
      count += 1
      # See if we have any training instances.  If not, we really can't guess anything.
      watcher = @training_watchers[user_id]
      next if watcher.nil?

      watcher_repo_progress = 0
      # For each observed repository in the training data . . .
      watcher.repositories.each do |watcher_repo|
        training_repo_progress = 0
        # Compare against all other repositories to calculate the Euclidean distance between them.
        @training_repositories.each do |training_repo_id, training_repo|
         # puts "Processing #{watcher_repo_progress + 1} / #{watcher.repositories.size} - #{training_repo_progress + 1} / #{@training_repositories.size}: #{Time.now.to_s}"
          training_repo_progress += 1

          # Skip over repositories we already know the watcher belongs to.     
          next if training_repo.watchers.include?(watcher)

          # Calculate the distance, culling for absolute non-matches (i.e., distance == Float::MAX)
          distance = NearestNeighbors.euclidian_distance(watcher_repo, training_repo)
          results[user_id][distance] = training_repo unless distance == Float::MAX
        end

        watcher_repo_progress += 1
      end
    end

    ret = []
    results.each do |user_id, distances|
      w = Watcher.new user_id

      distances.each do |distance, repo|
        w.repositories << repo
      end

      ret << w
    end

    ret
  end
end