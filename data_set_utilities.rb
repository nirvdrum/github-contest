module DataSetUtilities 

  def cross_validation(num_folds)
    folds = stratify(num_folds)

    folds.size.times do
      test_set = folds.delete_at(0)
      training_set = folds.inject {|reduced, current| reduced.nil? ? current : reduced + current}

      yield training_set, test_set

      folds << test_set
    end

    folds
  end

  def to_models

    Cache.fetch("data_set_to_models_#{object_id}") do
      watchers = {}
      repositories = {}

      raw_repositories = DataLoader.load_repositories

      # Discover watchers, repositories, and mappings.
      data_items.each do |sample|
        user_id, repo_id = sample

        watchers[user_id] ||= Watcher.new user_id

        unless repo_id.nil?
          repositories[repo_id] ||= Repository.new repo_id, raw_repositories[repo_id].name, raw_repositories[repo_id].created_at
          watchers[user_id].associate repositories[repo_id]
        end
      end

      # Map parent-child repo relationships.  Since raw_repositories may consist of repo <=> watchers or repo <=> repo
      # that do not exist in the data set, make sure we always look up in the local repo list.
      raw_repositories.each do |repo_id, repo|
        if !repositories[repo_id].nil? && !repo.parent.nil? && !repositories[repo.parent.id].nil?
          repositories[repo_id].parent = repositories[repo.parent.id]
        end
      end

      {:watchers => watchers, :repositories => repositories}
    end

  end

end