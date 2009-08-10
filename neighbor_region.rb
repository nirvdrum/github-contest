require 'memoize'

class NeighborRegion

  include Memoize

  attr_reader :id, :repositories

  def initialize(repository)
    root = Repository.find_root repository

    @id = root.id

    @repositories = Set.new [repository, root]

    #memoize :most_popular
    #memoize :most_forked
    #memoize :cut_point_count
  end

  def watchers
    watchers = Set.new

    @repositories.each {|repo| watchers.merge repo.watchers }

    watchers
  end

  def most_popular
    @repositories.sort { |x,y| x.watchers.size <=> y.watchers.size }.last
  end

  def most_forked
    @repositories.sort { |x,y| x.children.size <=> y.children.size }.last
  end

  def cut_point_count(other)
    (watchers & other.watchers).size
  end  

end