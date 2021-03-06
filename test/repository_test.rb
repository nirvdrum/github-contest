# Copyright 2009 Kevin J. Menard Jr.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'test_helper'
require 'repository'
require 'watcher'

class RepositoryTest < Test::Unit::TestCase

  def setup
    @repo = Repository.new '1234', 'user_a/yo', '2009-02-26'
  end

  def test_new
    id = '1234'
    name = 'user_a/yo'
    created_at = '2009-02-26'

    r = Repository.new id, name, created_at

    assert_equal id, r.id
    assert_equal 'user_a', r.owner
    assert_equal 'yo', r.name
    assert_equal created_at, r.created_at
    assert_nil r.parent
    assert_equal [], r.watchers
    assert_equal [], r.children
  end

  def test_set_parent
    parent = Repository.new '1234', 'user_a/yo', '2009-02-26'
    child = Repository.new '2345', 'user_b/yo', '2009-03-16'
  
    child.parent = parent

    assert_equal parent, child.parent
    assert_equal [child], parent.children
    assert_equal [], child.children
  end

  def test_equality
    a = Repository.new '1234', 'user_a/yo', '2009-02-26'
    b = Repository.new '1234', 'user_a/yo', '2009-02-26'

    # Two repositories with the same name, creation time, and parent should be equal.
    assert a == b

    # Two repositories with different parents should not be equal.
    a.parent = b
    assert a != b

    # Two repositories with different watchers should not be equal.
    a.parent = b.parent
    assert a == b
    a.watchers << Watcher.new('1')
    assert a != b
  end

  def test_eql
    a = Repository.new '1234', 'user_a/yo', '2009-02-26'
    b = Repository.new '1234', 'user_a/yo', '2009-02-26'

    # Two repositories with the same name, creation time, and parent should be equal.
    assert a.eql?(b)
    assert a.hash == b.hash

    # Two repositories with different parents should not be equal.
    a.parent = b
    assert !a.eql?(b)
    assert a.hash == b.hash # Hash on ID.

    # Two repositories with different watchers should not be equal.
    a.parent = b.parent
    assert a.eql?(b)
    assert a.hash == b.hash

    a.watchers << Watcher.new('1')
    assert !a.eql?(b)
    assert a.hash == b.hash # Hash on ID.
  end

  def test_watchers
    assert_equal [], @repo.watchers

    one = Watcher.new '1'
    two = Watcher.new '2'

    @repo.watchers << one
    @repo.watchers << two

    # Make sure the watchers list was populated correctly.
    assert_equal [one.id, two.id], @repo.watchers

    # Make sure a watcher can only appear once.
    @repo.watchers << one
    assert_equal [one.id, two.id], @repo.watchers
  end

  def test_popular_family_member_by_watchers_single_repo
    assert_equal @repo, Repository.popular_family_member_by_watchers(@repo)
  end

  def test_popular_family_member_by_watchers
    parent = Repository.new '1234', 'user_a/yo', '2009-02-26'
    child = Repository.new '2345', 'user_b/yo', '2009-03-16'
    grandchild_a = Repository.new '6790', 'user_c/yo', '2009-05-08'
    grandchild_b = Repository.new '2368', 'user_c/yo', '2009-05-09'

    # Establish family bond.
    child.parent = parent
    grandchild_a.parent = child
    grandchild_b.parent = child

    w1 = Watcher.new('2')
    w2 = Watcher.new('6')

    parent.watchers << w1
    parent.watchers << w2

    grandchild_a.watchers << Watcher.new('7')

    grandchild_b.watchers << Watcher.new('8')
    grandchild_b.watchers << w1
    grandchild_b.watchers << w2

    [parent, child, grandchild_a, grandchild_b].each do |repo|
      assert_equal grandchild_b, Repository.popular_family_member_by_watchers(repo)
    end
  end

  def test_popular_family_member_by_forks_single_repo
    assert_equal @repo, Repository.popular_family_member_by_forks(@repo)
  end

  def test_popular_family_member_by_forks
    parent = Repository.new '12341', 'user_a/yo', '2009-02-26'
    child = Repository.new '2345', 'user_b/yo', '2009-03-16'
    grandchild_a = Repository.new '6790', 'user_c/yo', '2009-05-08'
    grandchild_b = Repository.new '2368', 'user_c/yo', '2009-05-09'

    # Establish family bond.
    child.parent = parent
    grandchild_a.parent = child
    grandchild_b.parent = child

    [parent, child, grandchild_a, grandchild_b].each do |repo|
      assert_equal child, Repository.popular_family_member_by_forks(repo)
    end
  end

  def test_related
    parent = Repository.new '12341', 'user_a/yo', '2009-02-26'
    child = Repository.new '2345', 'user_b/yo', '2009-03-16'
    grandchild_a = Repository.new '6790', 'user_c/yo', '2009-05-08'
    grandchild_b = Repository.new '2368', 'user_c/yo', '2009-05-09'

    # Establish family bond.
    child.parent = parent
    grandchild_a.parent = child
    grandchild_b.parent = child

    repositories = [parent]
    non_related = Repository.new '367734', 'user_q/not_related', '2009-07-02'

    repositories.each do |first|
      # Make sure all the various players in the family tree are related.
      repositories.each do |second|
        assert first.related?(second)
      end

      assert !first.related?(non_related)
    end
  end
  
  def test_to_s
    assert_equal '1234:user_a/yo,2009-02-26', @repo.to_s

    with_parent = Repository.new '2356', 'user_b/yo', '2009-03-21'
    with_parent.parent = @repo

    assert_equal '2356:user_b/yo,2009-03-21,1234', with_parent.to_s
  end

  def test_associate
    watcher = Watcher.new '1'
    repo = Repository.new '1234'

    repo.associate watcher

    # Check that bi-directional mappings are set up.
    assert_equal [watcher.id], repo.watchers
    assert_equal [repo.id], watcher.repositories
  end  
end