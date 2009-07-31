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

end