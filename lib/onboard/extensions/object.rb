require 'json' # std library

begin
  require 'ya2yaml'
  $ya2yaml_available = true
rescue LoadError
  $ya2yaml_available = false
end

require 'facets/na'
require 'facets/hash'

class Object

  def to_(what)
    if what.to_s == 'json'
      begin
        json = JSON.pretty_generate(self)
        return json
      rescue NoMethodError
        return self.to_json
      end
    elsif $ya2yaml_available and what.to_s == 'yaml'
      return self.ya2yaml
    else
      method(('to_' + what.to_s).to_sym).call
    end
  end

  def deep?
    respond_to? :each or respond_to? :each_pair
  end

  def deep_map(&block)
    if self.respond_to? :each_pair
      out = {}
      self.each_pair do |k, v|
        if v.deep?
          new_k, new_v = block.call(k, NA)[0], v.deep_map(&block)
        else
          new_k, new_v = block.call(k, v)
        end
        out[new_k] = new_v
      end
      return out
    elsif self.respond_to? :each
      out = []
      self.each do |x|
        out << x.deep_map(&block)
      end
      return out
    else
      return block.call(NA, self)[1]
    end
  end

end


