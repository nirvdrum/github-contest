# Manages bi-directional relationships between Watcher and Repository instances.  Also ensures
# set semantics of repository list.
class RepositorySet < Array
  attr_accessor :watcher

  def <<(repository)
    unless include?(repository)
      super repository

      repository.watchers << watcher
    end
  end

  def delete(repository)
    super repository

    repository.watchers.delete(watcher) if repository.watchers.include?(watcher)
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
    @repositories.watcher = self
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
      "#{id}:" + @repositories.collect { |repo| "#{repo.id}" }.join(',')
    end
  end

  def self.from_data_set(data_set,marshal_name=nil)
    watchers = {}
    repositories = {}
    mappings = {}

    file_name = marshal_name.nil? ? nil : "tmp/watcher_from_data_set_#{marshal_name}.dump"

    # Try to load marshalled data first, if appropriate.
    if !file_name.nil? && File.exists?(file_name)
      File.open(file_name, 'r') do |file|
        marshalled = Marshal.load file
        watchers = marshalled[:watchers]
        repositories = marshalled[:repositories]
        mappings = marshalled[:mappings]
      end

    else
      # Discover watchers, repositories, and mappings.
      data_set.data_items.each do |sample|
        user_id, repo_id = sample

        watchers[user_id] ||= Watcher.new user_id

        unless repo_id.nil?
          repositories[repo_id] ||= Repository.new repo_id

          mappings[user_id] ||= []
          mappings[user_id] << repo_id
        end
      end

      # Marshall the data out if appropriate.
      if !file_name.nil?
        File.open(file_name, 'w') do |file|
          marshalled = {
                  :watchers => watchers,
                  :repositories => repositories,
                  :mappings => mappings
          }

          Marshal.dump marshalled, file
        end
      end
    end

    # Connect the watchers and repositories.  This needs to be a separate step because of the circular
    # relationship between the two.  Marshalling does not like circular relationships.
    connect_watchers_to_repositories watchers, repositories, mappings
    watchers
  end

  private

  def self.connect_watchers_to_repositories(watchers, repositories, mappings)
    count = 0
    mappings.each do |user_id, repository_ids|
      repository_ids.each do |repo_id|
        watchers[user_id].repositories << repositories[repo_id]
      end
      count += 1

      break if count == 2500
    end
  end

end