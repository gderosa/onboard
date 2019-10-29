require 'facets/hash' # http://facets.rubyforge.org/

class Hash

  # Filter nested data in a granular way, only letting in what specified in +allowed+,
  # as in the following example:
  #
  #   data = {
  #     :a => 1,
  #     :b => 2,
  #     :c => {
  #       :x => 10,
  #       :y => 20,
  #       :z => 30
  #     }
  #   }
  #
  #   allowed = {
  #     :b => true,
  #     :c => {
  #       :y => true
  #     }
  #   }
  #
  #   data.let_in(allowed)  #=>  {:b => 2, :c => {:y => 20}}
  def let_in(allowed)
    result = {}
    allowed.each_pair do |k, v|
      case v
      when Hash
        result[k] = self[k].let_in(v) if self[k].respond_to? :let_in
      else
        result[k] = self[k] if v
      end
    end
    return result
  end

  # Can't find a reason why:
  #
  #   Array#select #=> an Array
  #   Array#partition #=> an Array
  #
  #   Hash#select #=> an Hash
  #
  # and:
  #
  #   Hash#partition #=> an Array # :-(
  #
  # Hash#partition_hash tries to fix this inconsistence:
  #
  #    h = {'a' => 1, 'b' => 2, 'c' => 3}
  #    good, bad = h.partition_hash {|key, val| key < 'b' or val > 2}
  #    good #=> {"a"=>1, "c"=>3}
  #    bad #=> {"b"=>2}
  #
  def partition_hash(&blk)
    yes = {}
    no = {}
    each_pair do |k, v|
      if blk.call(k, v)
        yes[k] = v
      else
        no[k] = v
      end
    end
    return yes, no
  end


  # Some sugar:

  def recursively_stringify_keys
    recurse{|h| h.rekey{|k| k.to_s}}
  end
  def recursively_simbolize_keys
    recurse{|h| h.rekey{|k| k.to_sym}}
  end
  def recursively_stringify_keys!
    recurse!{|h| h.rekey{|k| k.to_s}}
  end
  def recursively_simbolize_keys!
    recurse!{|h| h.rekey{|k| k.to_sym}}
  end

  # non-facets

  def symbolize_all
    h = {}
    each_pair do |k, v|
      h[k.to_sym] = v.to_sym
    end
    return h
  end

  def symbolize_values
    h = {}
    each_pair do |k, v|
      h[k] = v.to_sym
    end
    return h
  end

end


