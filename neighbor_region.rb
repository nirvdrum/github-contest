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

require 'memoize'

class NeighborRegion

  include Memoize

  attr_reader :id, :repositories

  def initialize(repository)
    root = Repository.find_root repository

    @id = root.id

    @repositories = Set.new [repository, root]

    memoize :most_popular
    memoize :most_forked
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