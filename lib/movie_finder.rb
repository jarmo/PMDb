class MovieFinder
  MOVIES_CACHE = File.dirname(__FILE__) + "/movies.yml"

  def initialize(options)
    @options = options
  end

  def movies
    @movies = File.exists?(MOVIES_CACHE) ? File.open(MOVIES_CACHE, "r") {|f| YAML.load f} : scan_movies
  end

  def scan_movies
    movies = parse movie_files
    File.open(MOVIES_CACHE, "w") {|f| YAML.dump movies, f}
    movies
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
    dirs.each_pair do |dir, files|
     parent_dir = Pathname.new(dir)
     movie_objects = Parallel.map(files, :in_threads => 5) do |file|
      {imdb: IMDb.new(file), path: file.dirname.relative_path_from(parent_dir).to_s, mtime: file.mtime.strftime("%d.%m.%Y")}
     end
     dirs[dir] = movie_objects
    end
    dirs
  end

end
