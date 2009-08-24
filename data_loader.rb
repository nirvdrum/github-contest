require 'rubygems'
require 'ai4r'
require 'memoize'

require 'repository'
require 'watcher'
require 'cache'

class DataLoader

  def self.load_watchings
    Cache.fetch('watchings') do
      data_labels = ['user_id', 'repo_id']
      data_items = []

      IO.foreach(File.join(data_dir, 'data.txt')) do |line|
        data_items << line.strip.split(':')
      end

      data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => data_items)
      data_set
    end
  end

  def self.load_repositories
    Cache.fetch('repositories') do
      @@repositories ||= {}
      return @@repositories unless @@repositories.empty?

      relationships = {}

      IO.foreach(File.join(data_dir, 'repos.txt')) do |line|
        repo_id, repo_data = line.strip.split(':')
        name, created_at, parent_id = repo_data.split(',')

        # Add the repository to the result hash.
        @@repositories[repo_id] = Repository.new(repo_id, name, created_at)

        # Keep track of parent-child relationships.
        relationships[repo_id] = parent_id unless parent_id.nil?
      end

      # Now that all the repositories have been loaded, establish any parent-child relationships.
      relationships.each do |child_id, parent_id|
        @@repositories[child_id].parent = @@repositories[parent_id]
      end

      # Load in the watchers.
      watchers = {}
      IO.foreach(File.join(data_dir, 'data.txt')) do |line|
        user_id, repo_id = line.strip.split(':')
        watcher = watchers[user_id] || Watcher.new(user_id)
        watchers[user_id] = watcher
        @@repositories[repo_id].watchers << watcher
      end

      @@repositories
    end
  end

  def self.load_predictings
    Cache.fetch('predictings') do
      data_labels = ['user_id']
      data_items = []

      IO.foreach(File.join(data_dir, 'test.txt')) do |line|
        data_items << [line.strip]
      end

      data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => data_items)
      data_set
    end
  end

  def self.data_dir
    @@data_dir ||= 'data'
  end
end
