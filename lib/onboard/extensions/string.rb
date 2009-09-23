class String
  # add a trailing slash if not present, handy for URLs etc.
  def trailing_slash
    sub /([^\/]$)/, '\1/'
  end
  
  # transform /path/to/something.ext into /path/to/something/
  def to_dir
    sub /(\.[^\.]+$)/, ''
  end
end
