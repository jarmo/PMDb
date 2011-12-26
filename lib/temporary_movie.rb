class TemporaryMovie < Movie
  
  private

  def parse(name)
    @name, @year = parse_name_and_year name
  end
end
