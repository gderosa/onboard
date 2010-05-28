class OnBoard
  module Network
    module Routing
      class Rule

        def self.getAll
          all = []
          `ip rule show`.each_line do |line|
            if line =~ 
                /^(\d+):\s+from\s+(\S+)(to\s+(\S))?\s+(fwmark\s+(\S+)\s+)?(lookup|table)\s+(\S+)/
              all << self.new(
                :prio   => $1,
                :from   => $2,
                :to     => $4,
                :fwmark => $6,
                :table  => $8
              )
            end
          end
          return all
        end

        attr_reader :prio, :from, :to, :table, :fwmark

        def initialize(h)
          @prio   = h[:prio]
          @from   = h[:from]
          @to     = h[:to]
          @table  = h[:table]
          @fwmark = h[:fwmark]
        end

        def data
          {
            'prio'  => @prio,
            'from'  => @from,
            'to'    => @to,
            'table' => @table
          }
        end

      end
    end
  end
end
