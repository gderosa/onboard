class OnBoard
  module Util
    class Version < Array # Inherit or encapsulate?
      include Comparable
      def initialize(arg)
        begin
          super arg
        rescue TypeError # Assuming is a String
          @to_s = arg
          super arg.split('.').map{|s| s.to_i}
        end
      end
      def to_s
        @to_s or join '.'
      end
      def <=>(other)
        if other.is_a? self.class
          super(other)
        else
          self.<=>(self.class.new(other))
        end
      end
    end
  end
end

class String
  alias __compare_orig <=>
  def <=>(other)
    if other.is_a? OnBoard::Util::Version
      -(other <=> self)
    else
      __compare_orig other
    end
  end
end
