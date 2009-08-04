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

  def delete(repository)
    super repository

    repository.watchers.delete(watcher) if repository.watchers.include?(watcher)
  end

  def ==(other)
    self.size == other.size && (self - other).empty?
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
  alias_method :eql?, :==

  def hash
    @id.hash
  end

  def to_s
    if @repositories.empty?
      "#{id}"
    else
      "#{id}:" + @repositories.collect { |repo| "#{repo.id}" }.join(',')
    end
  end

  def self.from_data_set(data_set,marshal_name=nil)

    Cache.fetch("watcher_from_data_set_#{marshal_name}") do
      watchers = {}
      repositories = {}

      # Discover watchers, repositories, and mappings.
      data_set.data_items.each do |sample|
        user_id, repo_id = sample

        watchers[user_id] ||= Watcher.new user_id

        unless repo_id.nil?
          repositories[repo_id] ||= Repository.new repo_id
          watchers[user_id].repositories << repositories[repo_id]
        end
      end

      watchers
    end

  end

end