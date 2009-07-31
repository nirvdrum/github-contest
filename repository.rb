class Repository

  attr_reader :name, :created_at
  attr_accessor :parent

  def initialize(name, created_at)
    @name = name
    @created_at = created_at
  end

  def ==(other)
    return false if other.nil?

    @name == other.name &&
    @created_at == other.created_at &&
    @parent == other.parent
  end

end