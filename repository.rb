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

end