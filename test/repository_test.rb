require 'test_helper'
require 'repository'

class RepositoryTest < Test::Unit::TestCase

  def test_new
    name = 'user_a/yo'
    created_at = '2009-02-26'

    r = Repository.new name, created_at

    assert_equal name, r.name
    assert_equal created_at, r.created_at
    assert_nil r.parent
    assert_equal [], r.watchers
    assert_equal [], r.children
  end

  def test_set_parent
    parent = Repository.new 'user_a/yo', '2009-02-26'
    child = Repository.new 'user_b/yo', '2009-03-16'
  
    child.parent = parent

    assert_equal parent, child.parent
    assert_equal [child], parent.children
    assert_equal [], child.children
  end

  def test_equality
    a = Repository.new 'user_a/yo', '2009-02-26'
    b = Repository.new 'user_a/yo', '2009-02-26'

    # Two repositories with the same name, creation time, and parent should be equal.
    assert a == b

    # Two repositories with different parents should not be equal.
    a.parent = b
    assert a != b

    # Two repositories with different watchers should not be equal.
    a.parent = b.parent
    assert a == b
    a.watchers << '1'
    assert a != b
  end

  def test_watchers
    a = Repository.new 'user_a/yo', '2009-02-26'
    assert_equal [], a.watchers

    a.watchers << '1234'
    a.watchers << '2356'

    assert_equal ['1234', '2356'], a.watchers
  end

  def test_popular_family_member_by_watchers_single_repo
    repo = Repository.new 'user_a/yo', '2009-02-26'

    assert_equal repo, Repository.popular_family_member_by_watchers(repo)
  end

  def test_popular_family_member_by_watchers
    parent = Repository.new 'user_a/yo', '2009-02-26'
    child = Repository.new 'user_b/yo', '2009-03-16'
    grandchild_a = Repository.new 'user_c/yo', '2009-05-08'
    grandchild_b = Repository.new 'user_c/yo', '2009-05-09'

    # Establish family bond.
    child.parent = parent
    grandchild_a.parent = child
    grandchild_b.parent = child

    parent.watchers << '2'
    parent.watchers << '6'

    grandchild_a.watchers << '7'

    grandchild_b.watchers << '8'
    grandchild_b.watchers << '2'
    grandchild_b.watchers << '6'

    [parent, child, grandchild_a, grandchild_b].each do |repo|
      assert_equal grandchild_b, Repository.popular_family_member_by_watchers(repo)
    end
  end

  def test_popular_family_member_by_forks_single_repo
    repo = Repository.new 'user_a/yo', '2009-02-26'

    assert_equal repo, Repository.popular_family_member_by_forks(repo)
  end

  def test_popular_family_member_by_forks
    parent = Repository.new 'user_a/yo', '2009-02-26'
    child = Repository.new 'user_b/yo', '2009-03-16'
    grandchild_a = Repository.new 'user_c/yo', '2009-05-08'
    grandchild_b = Repository.new 'user_c/yo', '2009-05-09'

    # Establish family bond.
    child.parent = parent
    grandchild_a.parent = child
    grandchild_b.parent = child

    [parent, child, grandchild_a, grandchild_b].each do |repo|
      assert_equal child, Repository.popular_family_member_by_forks(repo)
    end
  end
end