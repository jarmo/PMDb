class MovieFinder
  def initialize(options)
    @options = options
  end

  def movies
    imdb_info(objectify(files(directories)))
  end

  private

  def directories
    @options["dirs"].reduce([]) do |memo, dir|
      memo << Pathname.new(dir).children.select(&:directory?)
    end.flatten
  end

  def files(dirs)
    dirs.reduce([]) do |memo, dir|
      file = dir.children.detect do |f|
        f.file? && (f.nfo? || f.video?)
      end
      memo << file
    end
  end

  def objectify(files)
    Parallel.map(files, :in_threads => 5) do |f|
      {imdb: IMDb.new(f), path: f.dirname.to_s, mtime: f.mtime}
    end
  end

  def imdb_info(objs)
    EM.synchrony do
      multi = EM::Synchrony::Multi.new
      objs.each_with_index do |obj, i|
        multi.add i + 1_000_000, EM::HttpRequest.new(obj[:imdb].url).aget
      end

      res = multi.perform
      require "pp"
      pp res.responses[:callback].keys
      puts "===================================================================="
      pp res.responses[:callback][1_000_000].response

      EM.stop
    end
    objs
  end
end
