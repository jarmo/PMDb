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
    end.compact
  end

  def objectify(files)
    Parallel.map(files, :in_threads => 5) do |f|
      {imdb: IMDb.new(f), path: f.dirname.to_s, mtime: f.mtime}
    end
  end

  def imdb_info(objs)
    objs.each_slice(5) do |bulk_objs|
      Parallel.each(bulk_objs, :in_threads => 5) do |obj|
        obj[:imdb].parse_response Net::HTTP.get_response(URI.parse(obj[:imdb].scraping_url)).body
      end
    end

    objs
  end
end
