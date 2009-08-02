class NearestNeighbors

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

end