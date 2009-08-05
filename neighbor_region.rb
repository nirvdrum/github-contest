class NeighborRegion

  attr_reader :id, :repositories

  def initialize(repository)
    root = Repository.find_root repository

    @id = root.id

    @repositories = Set.new [repository, root]
  end

  def watchers
    watchers = Set.new

    @repositories.each {|repo| watchers.merge repo.watchers }

    watchers
  end

end