class Watcher

  attr_reader :id, :repositories

  def initialize(id)
    @id = id

    @repositories = []
  end

  def to_s
    if @repositories.empty?
      "#{id}"
    else
      @repositories.collect { |repo| "#{id}:#{repo.id}" }.join('\n')
    end
  end

end