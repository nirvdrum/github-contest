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

# Ensures set semantics of repository list and handle coercion of strings and repositories.
class RepositorySet < Array
  def <<(repository)
    id = repository.is_a?(Repository) ? repository.id : repository

    super id unless include?(id)
  end

  def delete(repository)
    repository.is_a?(Repository) ? super(repository.id) : repository
  end

  def ==(other)
    self.size == other.size && (self - other).empty?
  end
end

class Watcher

  attr_reader :id, :repositories

  def initialize(id)
    @id = id

    @repositories = RepositorySet.new
  end

  def associate(repository)
    @repositories << repository
    repository.watchers << self
  end

  def ==(other)
    return false if other.nil?

    id == other.id
  end
  alias_method :eql?, :==

  def hash
    @id.hash
  end

  def to_s
    if @repositories.empty?
      "#{id}"
    else
      "#{id}:" + @repositories.collect { |repo| "#{repo}" }.join(',')
    end
  end 

end