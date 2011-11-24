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
    EM.synchrony do
      i = -1
      objs.each_slice(1) do |bulk_objs|
        multi = EM::Synchrony::Multi.new
        bulk_objs.each do |obj|
          multi.add i += 1, EM::HttpRequest.new(obj[:imdb].scraping_url).aget
        end

        res = multi.perform
        Parallel.each(res.responses[:callback], :in_threads => 5) do |k, v|
          objs[k][:imdb].parse_response v.response
        end
      end
    end

    objs
  end
end
