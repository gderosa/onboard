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
  alias include_many? include_ary?
  def sum
    inject {|sum, n| sum + n } 
  end
end
