class Hash
  # Can't find a reason why: 
  #
  # Array#select #=> an Array
  # Array#partition #=> an Array
  #
  # Hash#select #=> an Hash
  #
  # and:
  #
  # Hash#partition #=> an Array # :-(
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

  require 'facets/hash' # http://facets.rubyforge.org/

  # Some sugar:

  def recursively_stringify_keys
    recursive{|h| h.rekey{|k| k.to_s}}
  end
  def recursively_simbolize_keys
    recursive{|h| h.rekey{|k| k.to_sym}}
  end
  def recursively_stringify_keys!
    recursive!{|h| h.rekey{|k| k.to_s}}
  end
  def recursively_simbolize_keys!
    recursive!{|h| h.rekey{|k| k.to_sym}}
  end

  # non-facets
  
  def symbolize_all
    h = {}
    each_pair do |k, v|
      h[k.to_sym] = v.to_sym
    end
    return h
  end

end


