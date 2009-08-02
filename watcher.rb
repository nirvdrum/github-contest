# Manages bi-directional relationships between Watcher and Repository instances.  Also ensures
# set semantics of repository list.
class RepositorySet < Array
  attr_accessor :watcher

  def <<(repository)
    unless include?(repository)
      super repository

      repository.watchers << watcher
    end
  end
end

class Watcher

  attr_reader :id, :repositories

  def initialize(id)
    @id = id

    @repositories = RepositorySet.new
    @repositories.watcher = self
  end

  def ==(other)
    return false if other.nil?

    id == other.id
  end

  def to_s
    if @repositories.empty?
      "#{id}"
    else
      @repositories.collect { |repo| "#{id}:#{repo.id}" }.join('\n')
    end
  end

end