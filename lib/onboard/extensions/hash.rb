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
class Hash
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
end

if $0 == __FILE__
  h = {'a' => 1, 'b' => 2, 'c' => 3}
  yes, no = h.partition_hash {|key, val| key < 'b' or val > 2} 
  p yes
  p no
end
