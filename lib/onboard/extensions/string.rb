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

  def smart_encode(to)
    begin
      return encode(to)
    rescue EncodingError
      good_encoding = valid_encodings.find{|enc| enc != Encoding::ASCII_8BIT}
      if good_encoding
        force_encoding good_encoding
        begin
          return encode(to)
        rescue EncodingError # last resort
          return to_asciihex
        end
      else # last resort
        return to_asciihex
      end
    end
  end

  def valid_encodings(subset=Encoding.list)
    working_copy    = self.dup
    ary = Array.new
    subset.each do |enc|
      working_copy.force_encoding enc
      begin
        working_copy.encode 'utf-8'
        working_copy =~ / test /
        # the two lines above might raise EncodingError or ArgumentError
        ary << enc
      rescue EncodingError, ArgumentError
        # do not add anything to ary
      end
    end
    return ary
  end

  def to_asciihex
    out   = ''.force_encoding Encoding::ASCII
    self.each_line do |line|
      # escape the backslash only if it's part of a hex sequence, like \xF9
      line.gsub!(/(\\)(x\h\h)/, '\\x5C\2')
      line.each_byte do |byte|
        if byte < 128
          out << byte.chr
        else
          out << "\\x#{byte.to_s(16).upcase}"
        end
      end
    end
    out
  end

  def from_asciihex(encoding=Encoding::BINARY)
    out = ''.force_encoding encoding
    self.each_line do |line|
      out << line.gsub(/(\\x\h\h)/) do |capture|
        eval %Q{"#{capture}"}
      end
    end
    out
  end

  def hex2bin
    [self].pack('H*')
  end

  alias to_i_orig to_i

  # A smarter to_i which automatically guess the base of
  # "0xff", "0377", "0b11111111"" and "255"
  # if no argument is provided
  #
  def to_i(*args)

    return to_i_orig(*args) if args.length > 0 and not args.include? :guess_octal_always

    case self
    when /^\s*0x(\h+)\s*$/      # hexadecimal
      return $1.to_i_orig(16)
    when /^\s*0o([0-7]+)\s*$/   # unambiguous octal
      return $1.to_i_orig(8)
    when /^\s*0b([01]+)\s*$/    # binary ("0" and "1")
      return $1.to_i_orig(2)
    else
      if args.include? :guess_octal_always
        if self =~ /^\s*0([0-7]+)\s*$/ # ambiguous octal
          return $1.to_i_orig(8)
        end
      end
    end

    return to_i_orig(*args)

  end

  # Turn
  #  'AAA BBB\ CCC'
  # into
  #   ['AAA', 'BBB CCC']
  def split_unescaping_spaces
    strip!
    gsub(/([^\\])\s+/, "\\1\0").split("\0").map{|x| x.gsub '\ ',  ' '}
  end

  def is_uri?
    self =~ /^\w+:\//i
  end

end
