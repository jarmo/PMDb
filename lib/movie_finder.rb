class MovieFinder
  MOVIES_CACHE = File.dirname(__FILE__) + "/movies.yml"
  HIDDEN_MOVIES = File.dirname(__FILE__) + "/hidden.yml"

  def initialize(options)
    @options = options
    @hidden_movies = File.exists?(HIDDEN_MOVIES) ? File.open(HIDDEN_MOVIES, "r") {|f| YAML.load f} : {}
  end

  def movies
    movies = File.exists?(MOVIES_CACHE) ? File.open(MOVIES_CACHE, "r") {|f| YAML.load f} : rescan
    filter_hidden movies
  end

  def rescan
    movies = parse filter_hidden(movie_files)
    File.open(MOVIES_CACHE, "w") {|f| YAML.dump movies, f}
    movies
  end

  def temporary(movies)
    parse "temporary" => movies.split("\n").map {|m| {file: m.strip, path: m, mtime_s: "-"}}
  end

  def filter_hidden movies
    @hidden_movies.each_pair do |dir, hidden_movies|
      movies_in_dir = movies[dir]
      next unless movies_in_dir
      movies_in_dir.delete_if {|movie| hidden_movies.include? movie[:path]}
    end
    movies
  end

  def hide_movie dir, path
    @hidden_movies[dir] ||= []
    @hidden_movies[dir] << path
    File.open(HIDDEN_MOVIES, "w") {|f| YAML.dump @hidden_movies, f}
  end

  private

  def movie_files
    print "Searching movies..."
    t = Time.now
    result = @options["directories"].reduce({}) do |result_memo, dir|
      movie_files_in_dirs = []
      dir = dir.gsub(File::ALT_SEPARATOR || "\\", File::SEPARATOR)

      if File.exist? dir
        dirs = Pathname.new(dir).children.select(&:directory?)
        movie_files_in_dirs = dirs.reduce([]) do |memo, d|
          files = d.children.select do |f|
            f.file? && (f.nfo? || f.video?)
          end

          file = files.detect(&:nfo?) || files.first
          
          if file
            file_mtime = file.mtime
            memo << {path: file.dirname.basename.to_s, mtime: file_mtime, mtime_s: file_mtime.strftime("%d.%m.%Y"), file: file}
          end

          memo
        end
      end

      result_memo[dir] ||= []
      result_memo[dir] += movie_files_in_dirs
      result_memo
    end
    print " #{result.values.flatten.size} movies found in #{Time.now - t}s\n"

    result
  end

  def parse(dirs)
    print "Fetching data from IMDb..."
    t = Time.now
    dirs.each_pair do |dir, movies|
     movie_objects = Parallel.map_with_index(movies, :in_threads => 10) do |movie, i|
      print "." if i % 5 == 0
      movie[:movie] = movie[:file].is_a?(String) ? TemporaryMovie.new(movie[:file]) : Movie.new(movie[:file])
      movie
     end
     dirs[dir] = movie_objects
    end
    print " done in #{Time.now - t}s\n"
    dirs
  end

end
