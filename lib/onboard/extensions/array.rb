class Array

  # Returns true if all elements of other are elements of self
  # [1, 2, 3, 4, 5].include_ary? [2, 3] # ==> true
  # [1, 2, 3, 4, 5].include_ary? [2, 6] # ==> false
  def include_ary?(other)
    other.each do |elem|
      return false unless self.include? elem
    end
    return true
  end

  def include_any_of?(list)
    (self & list).length > 0
  end

  alias include_many?   include_ary?
  alias include_all_of? include_ary?

  def sum
    inject {|sum, n| sum + n }
  end

  def <(other)
    (self <=> other) == -1
  end

  def <=(other)
    (self <=> other) == -1 or (self <=> other) == 0
  end

  def >=(other)
    (self <=> other) == +1 or (self <=> other) == 0
  end

  def >(other)
    (self <=> other) == +1
  end

end
