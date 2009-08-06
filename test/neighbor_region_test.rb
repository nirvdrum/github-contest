require 'test_helper'
require 'repository'
require 'neighbor_region'
require 'watcher'

class NeigborRegionTest < Test::Unit::TestCase

  def test_region_id
    parent = Repository.new '1234'
    child = Repository.new '2345'

    child.parent = parent

    parent_region = NeighborRegion.new parent
    assert_equal parent.id, parent_region.id    

    # A region is always identified by the repository root.
    child_region = NeighborRegion.new child
    assert_equal parent.id, child_region.id
  end

  def test_repositories
    r1 = Repository.new '1234'
    region = NeighborRegion.new r1
    assert_equal Set.new([r1]), region.repositories

    r2 = Repository.new '2345'
    region.repositories << r2
    assert_equal Set.new([r1, r2]), region.repositories
  end

  def test_repositories_when_inited_with_descendant
    parent = Repository.new '1234'
    child = Repository.new '2345'
    grandchild = Repository.new '6790'

    child.parent = parent
    grandchild.parent = child

    region = NeighborRegion.new grandchild
    assert_equal Set.new([parent, grandchild]), region.repositories
  end

  def test_watchers
    r1 = Repository.new '1234'
    r2 = Repository.new '2345'

    r2.parent = r1

    w1 = Watcher.new '1'
    w2 = Watcher.new '2'
    w3 = Watcher.new '3'

    r1.watchers << w1
    r2.watchers << w2
    r2.watchers << w3

    region = NeighborRegion.new r2
    assert_equal Set.new([w1.id, w2.id, w3.id]), region.watchers
  end

  def test_most_popular
    r1 = Repository.new '1234'
    r2 = Repository.new '2345'

    r2.parent = r1

    w1 = Watcher.new '1'
    w2 = Watcher.new '2'
    w3 = Watcher.new '3'

    r1.watchers << w1
    r2.watchers << w2
    r2.watchers << w3

    # r2 has the most watchers and thus should be the most popular.
    region = NeighborRegion.new r2
    assert_equal r2, region.most_popular
  end

  def test_cut_point_count
    r1 = Repository.new '1234'
    r2 = Repository.new '2345'

    w1 = Watcher.new '1'
    w2 = Watcher.new '2'
    w3 = Watcher.new '3'
    w4 = Watcher.new '4'

    r1.watchers << w1
    r1.watchers << w2
    r1.watchers << w3

    r2.watchers << w2
    r2.watchers << w3
    r2.watchers << w4

    # The two cut points are w2 and w3.  The relationship should be symmetric.
    first = NeighborRegion.new r1
    second = NeighborRegion.new r2
    assert_equal 2, first.cut_point_count(second)
    assert_equal 2, second.cut_point_count(first)
  end

end