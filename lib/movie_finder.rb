class MovieFinder
  MOVIES_CACHE = File.dirname(__FILE__) + "/movies.yml"
  HIDDEN_MOVIES = File.dirname(__FILE__) + "/hidden.yml"

  def initialize(options)
    @options = options
    @hidden_movies = File.exists?(HIDDEN_MOVIES) ? File.open(HIDDEN_MOVIES, "r") {|f| YAML.load f} : {}
  end

  def movies
    @movies = File.exists?(MOVIES_CACHE) ? File.open(MOVIES_CACHE, "r") {|f| YAML.load f} : rescan
    filter_hidden @movies
  end

  def rescan
    movies = parse movie_files
    File.open(MOVIES_CACHE, "w") {|f| YAML.dump movies, f}
    filter_hidden movies
  end

  def filter_hidden movies
    @hidden_movies.each_pair do |dir, hidden_movies|
      movies[dir].delete_if {|movie| hidden_movies.include? movie[:path]}
    end
    movies
  end

  def hide_movie dir, path
    @hidden_movies[dir] ||= []
    @hidden_movies[dir] << path
    File.open(HIDDEN_MOVIES, "w") {|f| YAML.dump @hidden_movies, f}
  end

  def to_json
    Yajl::Encoder.encode @movies
  end

  private

  def movie_files
    @options["directories"].reduce({}) do |result_memo, dir|
      movie_files_in_dirs = []
      dir = dir.gsub(File::ALT_SEPARATOR, File::SEPARATOR)

      if File.exist? dir
        dirs = Pathname.new(dir).children.select(&:directory?)
        movie_files_in_dirs = dirs.reduce([]) do |memo, d|
          file = d.children.detect do |f|
            f.file? && (f.nfo? || f.video?)
          end
          memo << file
        end.compact
      end

      result_memo[dir] ||= []
      result_memo[dir] += movie_files_in_dirs
      result_memo
    end
  end

  def parse(dirs)
    t = Time.now
    dirs.each_pair do |dir, files|
     parent_dir = Pathname.new(dir)
     movie_objects = Parallel.map(files, :in_threads => 20) do |file|
      {imdb: IMDb.new(file), path: file.dirname.relative_path_from(parent_dir).to_s, mtime: file.mtime, mtime_s: file.mtime.strftime("%d.%m.%Y")}
     end
     dirs[dir] = movie_objects
    end
    puts "scanning-parsing took #{Time.now - t}"
    dirs
  end

end
