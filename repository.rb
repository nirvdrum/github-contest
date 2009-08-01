class Repository

  attr_reader :name, :created_at, :watchers, :children, :parent

  def initialize(name, created_at)
    @name = name
    @created_at = created_at
    @watchers = []
    @children = []
  end

  def parent=(parent)
    @parent = parent
    parent.children << self
  end

  def ==(other)
    return false if other.nil?

    @name == other.name &&
    @created_at == other.created_at &&
    @parent == other.parent &&
    @watchers == other.watchers    
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

  private

  def self.find_root(repository)
    repository.parent.nil? ? repository : find_root(repository.parent)
  end

end