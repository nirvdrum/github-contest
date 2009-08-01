class Repository

  attr_reader :name, :created_at, :watchers
  attr_accessor :parent

  def initialize(name, created_at)
    @name = name
    @created_at = created_at
    @watchers = []
  end

  def ==(other)
    return false if other.nil?

    @name == other.name &&
    @created_at == other.created_at &&
    @parent == other.parent &&
    @watchers == other.watchers    
  end

end