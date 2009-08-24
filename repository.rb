# Ensures set semantics of watcher list and handles coercion between strings and repositories.
class WatcherSet < Array
  def <<(watcher)
    id = watcher.is_a?(Watcher) ? watcher.id : watcher

    super id unless include?(id)
  end

  def delete(watcher)
    watcher.is_a?(Watcher) ? super(watcher.id) : watcher
  end

  def ==(other)
    self.size == other.size && (self - other).empty?
  end
end

class Repository

  attr_reader :id, :owner, :name, :created_at, :watchers, :children, :parent

  def initialize(id, name=nil, created_at=nil)
    @id = id
    @owner, @name = name.split('/') unless name.nil?
    @created_at = created_at
    @children = []
    @watchers = WatcherSet.new
  end

  def parent=(parent)
    @parent = parent
    parent.children << self unless parent.nil?
  end

  def related?(other)
    root = Repository.find_root(self)

    queue = [root]

    while !queue.empty?
      repo = queue.pop
      return true if repo == other

      queue += repo.children
    end

    false
  end

  def associate(watcher)
    @watchers << watcher
    watcher.repositories << self
  end

  def ==(other)
    return false if other.nil?

    @name == other.name &&
    @created_at == other.created_at &&
    @parent == other.parent &&
    @watchers == other.watchers    
  end
  alias_method :eql?, :==

  def hash
    @id.hash
  end

  def to_s
    ret = "#{id}:#{owner}/#{name},#{created_at}"

    ret << ",#{parent.id}" unless parent.nil?

    ret
  end

  def self.popular_family_member_by_watchers(repository)
    root = find_root(repository)

    results = root.collect_watcher_count

    results[results.keys.max]
  end

  def self.popular_family_member_by_forks(repository)
    root = find_root(repository)

    results = root.collect_fork_count

    results[results.keys.max]
  end

  # Utility method used for recursive call portion of self.popular_family_member_by_watchers
  def collect_watcher_count
    ret = { watchers.size => self }

    children.collect do |child|
      # TODO (KJM 07/31/09) This will clobber an existing entry on duplicate watcher count.  For now I don't care much.
      ret.merge!(child.collect_watcher_count)
    end

    ret
  end

  # Utility method used for recursive call portion of self.popular_family_member_by_forks
  def collect_fork_count
    ret = { children.size => self }

    children.collect do |child|
      # TODO (KJM 07/31/09) This will clobber an existing entry on duplicate watcher count.  For now I don't care much.
      ret.merge!(child.collect_fork_count)
    end

    ret
  end

  def self.find_root(repository)
    repository.parent.nil? ? repository : find_root(repository.parent)
  end 

end