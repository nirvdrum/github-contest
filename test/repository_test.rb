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
  end

  def test_set_parent
    parent = Repository.new 'user_a/yo', '2009-02-26'
    child = Repository.new 'user_b/yo', '2009-03-16'

    child.parent = parent

    assert_equal parent, child.parent  
  end

  def test_equality

    a = Repository.new 'user_a/yo', '2009-02-26'
    b = Repository.new 'user_a/yo', '2009-02-26'

    # Two repositories with the same name, creation time, and parent should be equal.
    assert a == b

    # Two repositories with different parents should not be equal.
    a.parent = b
    assert a != b
  end

end