class IMDb
  attr_reader :url, :movie_id, :year, :name, :score, :votes, :genres

  def initialize(file)
    @file = file
    parse_file file
  end

  def parse_response response
    json = Yajl::Parser.parse response, :symbolize_keys => true
    return unless json[:Response] == "True"

    @name = json[:Title]
    @year = json[:Year]
    @score = json[:Rating]
    @votes = json[:Votes]
    @genres = json[:Genre].split(", ")
    @movie_id = json[:ID]
    @url = "http://akas.imdb.com/title/#{@movie_id}"
  end

  def scraping_url 
    suffix = @movie_id ? "i=#{@movie_id}" : "t=#{@name}&y=#{@year}"
    URI.encode "http://imdbapi.com/?#{suffix}"
  end

  private

  def parse_file(file)
    @url = parse_url file
    if @url
      @movie_id = @url.split("/").last
    else
      @name, @year = parse_name_and_year file
    end
  end

  def parse_url(file)
    return unless file.nfo?

    urls = URI.extract(@file.read, "http")
    urls.detect {|url| url =~ /imdb/i}
  end

  #def url_from(name)
    #URI.escape("http://akas.imdb.com/find?s=all&x=0&y=0&q=#{name}")
  #end

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

    parent_dirname = file.dirname.basename.to_s.gsub(/['"]/, "").gsub(/[-._]/, " ").squeeze(" ")
    excluded_regexp = /^(?:\(incomplete\)-)?(.*?)(?:#{excluded_keywords.join(" | ")})/i
    matched_name = parent_dirname.scan(excluded_regexp).flatten.first
    matched_name.empty? ? parent_dirname : matched_name
  end
end
