class String
  # add a trailing slash if not present, handy for URLs etc.
  def trailing_slash
    sub /([^\/]$)/, '\1/'
  end
  
  # transform /path/to/something.ext into /path/to/something/
  def to_dir
    sub /(\.[^\.]+$)/, ''
  end
  
  alias :oldeq :==

  # Handle the much common case when one of the two compared Strings
  # is a raw sequence of bytes, is bitwise identical to the other,
  # but the latter has its own encoding, so the result of '==' would have 
  # been false.
  def ==(other)

    if other.kind_of? String

      if
          (self.encoding  != Encoding::BINARY) and
          (other.encoding != Encoding::BINARY)

        return self.oldeq other

      elsif 
          (self.encoding  == Encoding::BINARY) and
          (other.encoding != Encoding::BINARY) 

        return self.oldeq other.dup.force_encoding(Encoding::BINARY) 

      elsif
          (self.encoding  != Encoding::BINARY) and
          (other.encoding == Encoding::BINARY)

        return other.oldeq self.dup.force_encoding(Encoding::BINARY)

      else

        return self.oldeq other

      end

    else

      return other.== self # NOTE: order is important!! 

    end

  end

end
