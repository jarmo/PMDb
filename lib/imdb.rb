class IMDb
  attr_reader :url, :movie_id, :year, :name, :score, :votes, :plot, :genres

  def initialize(file)
    @year = @name = @score = @votes = @plot = @genres = "N/A"
    parse_file file
    parse_imdb
    @url = url_from(@name) unless @url
  end

  def to_json
    Yajl::Encoder.encode :url => url, :movie_id => movie_id, :year => year, :plot => plot,
                         :name => name, :score => score, :votes => votes, :genres => genres
  end

  private

  def parse_file(file)
    @url = parse_url file
    @movie_id = @url.scan(/tt(\d+)/).flatten.first if @url
    @name, @year = parse_name_and_year file
  end

  def parse_imdb
    if @movie_id
      movie = ::Imdb::Movie.new(@movie_id)
    else
      result = ::Imdb::Search.new(@name)
      movie = result.movies.first if result.movies.size == 1
    end
    parse_response movie
  end

  def parse_response movie
    return unless movie

    @name = movie.title
    @year = movie.year.to_s
    @score = movie.rating
    @votes = movie.votes.to_s.reverse.gsub(/(\d{3})/, '\1 \2').reverse.strip
    @plot = movie.plot
    @genres = movie.genres.join(", ")
    @movie_id = movie.id
    @url = movie.url.gsub("/combined", "")
  end

  def parse_url(file)
    return unless file.nfo?

    urls = URI.extract(file.read, "http")
    urls.detect {|url| url =~ /imdb/i}
  end

  def url_from(name)
    URI.escape("http://akas.imdb.com/find?s=all&q=#{name}")
  end

  def parse_name_and_year(file)
    name = clean_dir(file)
    year = name.scan(/\s?((?:19|20)\d{2})/).flatten.last
    if year
      name_without_year = name.gsub(/\s?#{year}$/, "")
      name = name_without_year unless name_without_year.empty?
    end
    return name, year
  end

  def clean_dir(file)
    excluded_keywords = %w(
      unrated 720p 1080p 1080i repack rerip
      retail r5 dvd limited ee ts proper tc fs ws bluray hddvd subpack
      xvid divx dvdrip dvdscr xxx hdtv internal
      telesync subfix dirfix screener scr cam nfofix readnfo dsr workprint mdvdr bdrip
      stv extended dvdrscreener dvdscreener bdscr)

    dirname = file.dirname.basename.to_s.gsub(/['"]/, "").gsub(/[-._]/, " ").squeeze(" ")
    excluded_regexp = /^(?:\(incomplete\)-)?(.*?)(?:#{excluded_keywords.join(" | ")})/i
    matched_name = dirname.scan(excluded_regexp).flatten.first
    matched_name || dirname
  end
end
