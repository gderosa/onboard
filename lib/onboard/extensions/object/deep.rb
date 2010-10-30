
class Object

  def deep_map_values(&block)
    if respond_to? :each_pair
      out = {}
      each_pair do |k, v|
        out[k] = v.deep_map_values(&block)
      end
      return out
    elsif respond_to? :each
      out = []
      each do |x|
        out << x.deep_map_values(&block)
      end
      return out
    else
      return block.call(self)
    end
  end

  def deep_rekey(&block)
    if respond_to? :each_pair
      out = {}
      self.each_pair do |k, v|
        out[block[k]] = v.deep_rekey(&block)
      end
      return out
    elsif respond_to? :each
      out = []
      self.each do |x|
        out << x.deep_rekey(&block)
      end
      return out
    else
      return self
    end
  end

end


