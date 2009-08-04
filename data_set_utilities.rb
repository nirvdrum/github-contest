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

  def to_models(marshal_name=nil)

    Cache.fetch("watcher_from_data_set_#{marshal_name}_#{rand}") do
      watchers = {}
      repositories = {}

      # Discover watchers, repositories, and mappings.
      data_items.each do |sample|
        user_id, repo_id = sample

        watchers[user_id] ||= Watcher.new user_id

        unless repo_id.nil?
          repositories[repo_id] ||= Repository.new repo_id
          watchers[user_id].associate repositories[repo_id]
        end
      end

      {:watchers => watchers, :repositories => repositories}
    end

  end

end