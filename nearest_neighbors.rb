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

  def initialize(training_set)
    @training_watchers = Watcher.from_data_set training_set
    @training_repositories = {}

    @training_watchers.values.each do |watcher|
      watcher.repositories.each do |repo|
        @training_repositories[repo.id] ||= repo
      end
    end
  end

  def evaluate(test_set)
    # Build up a list of watcher objects from the test set.
    @test_instances = Watcher.from_data_set test_set

    results = {}

    # For each watcher in the test set . . .
    @test_instances.each do |user_id, watcher|
      results[user_id] = {}

      # See if we have any training instances.  If not, we really can't guess anything.
      watcher = @training_watchers[user_id]
      next if watcher.nil?

      # For each observed repository in the training data . . .
      watcher.repositories.each do |watcher_repo|

        # Compare against all other repositories to calculate the Euclidean distance between them.
        @training_repositories.each do |training_repo_id, training_repo|
          # Skip over repositories we already know the watcher belongs to.     
          next if training_repo.watchers.include?(watcher)

          # Calculate the distance, culling for absolute non-matches (i.e., distance == Float::MAX)
          distance = NearestNeighbors.euclidian_distance(watcher_repo, training_repo)
          results[user_id][distance] = training_repo unless distance == Float::MAX
        end
      end
    end

    results
  end
end