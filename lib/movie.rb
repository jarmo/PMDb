class Movie
  attr_reader :url, :movie_id, :year, :name, :score, :votes, :plot, :genres

  def initialize(name)
    @year = @name = @score = @votes = @plot = @genres = "N/A"
    parse name
    parse_imdb
    @url = url_from_name unless @url
  end

  def to_json
    MultiJson.dump :url => url, :movie_id => movie_id, :year => year, :plot => plot,
                         :name => name, :score => score, :votes => votes, :genres => genres
  end

  private

  def parse(file)
    @url = parse_url file
    @movie_id = @url.scan(/tt(\d+)/).flatten.first if @url
    @name, @year = parse_name_and_year file.dirname.basename.to_s
  end

  def parse_imdb
    if @movie_id
      movie = ::Imdb::Movie.new(@movie_id)
    else
      result = ::Imdb::Search.new(name_with_year)
      movie = if result.movies.size == 1
        result.movies.first
      else
        result.movies.find { |m| m.title == name_with_year }
      end
    end
    parse_response movie
  end

  def parse_response movie
    return unless movie

    @name, _ = parse_name_and_year(movie.title)
    @year = movie.year.to_s
    @score = movie.rating.to_s
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
  rescue ArgumentError
    # UTF-8 problems reading file...
  end

  def url_from_name
    URI.escape("http://akas.imdb.com/find?s=all&q=#{name_with_year}")
  end

  def name_with_year
    str = @name
    str += " (#{@year})" if @year != "N/A"
    str
  end

  def parse_name_and_year(movie_name)
    name = clean movie_name
    year = name.scan(/\s?((?:19|20)\d{2})/).flatten.last
    if year
      name_without_year = name.gsub(/[\s(]*#{year}[\s)]*$/, "")
      name = name_without_year unless name_without_year.empty?
    end
    return name, year || "N/A"
  end

  def clean(movie_name)
    excluded_keywords = %w(
      unrated 720p 1080p 1080i repack rerip
      retail r5 dvd limited ee ts proper tc fs ws bluray hddvd subpack
      xvid divx dvdrip dvdscr xxx hdtv internal
      telesync subfix dirfix screener scr cam nfofix readnfo dsr workprint mdvdr bdrip
      stv extended dvdrscreener dvdscreener bdscr dvd5 remastered x264 3d brrip festival)

    movie_name = movie_name.gsub(/['"]/, "").gsub(/[-._]/, " ").squeeze(" ")
    excluded_regexp = /^(?:\(incomplete\)-)?(.*?)(?:#{excluded_keywords.join(" | ")} | s\d+e\d+)/i
    matched_name = movie_name.scan(excluded_regexp).flatten.first
    matched_name || movie_name
  end
end
