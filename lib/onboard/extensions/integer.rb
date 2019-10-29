class Integer
  # returns a String of hexadecimal bytes, e.g. 02:13:af
  def to_byte_s(byte_separator=':')
    s = to_s(16)
    if s.length.odd?
      s = '0' + s
    end
    s.scan(/../).join(byte_separator)
  end
end
