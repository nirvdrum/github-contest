require 'rubygems'
require 'ai4r'

require 'repository'

class DataLoader

  def self.load_watchings(data_file='data/data.txt')
    data_labels = ['user_id', 'repo_id']
    data_items = []

    IO.foreach(data_file) do |line|
      data_items << line.strip.split(':')
    end

    data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => data_items)
    data_set
  end

  def self.load_repositories(data_file='data/repos.txt')
    repositories = {}

    relationships = {}

    IO.foreach(data_file) do |line|
      repo_id, repo_data = line.strip.split(':')
      name, created_at, parent_id = repo_data.split(',')

      # Add the repository to the result hash.
      repositories[repo_id] = Repository.new(name, created_at)

      # Keep track of parent-child relationships.
      relationships[repo_id] = parent_id unless parent_id.nil?
    end

    # Now that all the repositories have been loaded, establish any parent-child relationships.
    relationships.each do |child_id, parent_id|
      repositories[child_id].parent = repositories[parent_id]
    end

    repositories
  end

  def self.load_predictings(data_file='data/test.txt')
    data_labels = ['user_id']
    data_items = []

    IO.foreach(data_file) do |line|
      data_items << [line.strip]
    end

    data_set = Ai4r::Data::DataSet.new(:data_labels => data_labels, :data_items => data_items)
    data_set  
  end
end