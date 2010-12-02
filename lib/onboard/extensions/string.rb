class String

  class << self
    def random_binary(n_bytes)
      ( Array.new(n_bytes){ rand(0x100) } ).pack('c*') 
    end
    def random(n_chars, set)
      ary = set.to_a # any Enumerable
      s = ''
      n_chars.times do
        s << ary[rand(ary.length)]
      end
      return s
    end
  end

  # Lke String#crypt, but a random salt is auto-generated
  def salted_crypt
    crypt String.random(
      2,
      ('a'..'z').to_a + ('A'..'Z').to_a  + ('0'..'9').to_a + ['/', '.']   
    )
  end

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

      return self.oldeq other

    end

  end

  alias to_i_orig to_i

  # A smarter to_i which automatically guess the base of 
  # "0xff", "0377", "0b11111111"" and "255"
  # if no argument is provided
  #
  def to_i(*args)

    return to_i_orig(*args) if args.length > 0

    case self
    when /^\s*0x(\h*)\s*$/      # hexadecimal 
      return $1.to_i_orig(16)
    when /^\s*0o?([0-7]*)\s*$/  # octal
      return $1.to_i_orig(8)
    when /^\s*0b([01]*)\s*$/    # binary ("0" and "1")
      return $1.to_i_orig(2)
    else
      return to_i_orig
    end

  end

end
