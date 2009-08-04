# Ensures set semantics of repository list and handle coercion of strings and repositories.
class RepositorySet < Array
  def <<(repository)
    id = repository.is_a?(Repository) ? repository.id : repository

    super id unless include?(id)
  end

  def delete(repository)
    repository.is_a?(Repository) ? super(repository.id) : repository
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
      "#{id}:" + @repositories.collect { |repo| "#{repo}" }.join(',')
    end
  end

  def self.from_data_set(data_set,marshal_name=nil)

    Cache.fetch("watcher_from_data_set_#{marshal_name}_#{rand}") do
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