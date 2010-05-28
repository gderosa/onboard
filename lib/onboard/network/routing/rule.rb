class OnBoard
  module Network
    module Routing
      class Rule

        def self.getAll
          all = []
          `ip rule show`.each_line do |line|
            if line =~ 
                /^(\d+):\s+from\s+(\S+)(\s+to\s+(\S+))?(\s+fwmark\s+(\S+))?\s+(lookup|table)\s+(\S+)/
#                /^(\d+):\s+from\s+(\S+)(\s+to\s+(\S))?\s+(lookup|table)\s+(\S+)/
              all << self.new(
                :prio   => $1,
                :from   => ($2 || 'all'),
                :to     => ($4 || 'all'),
                :fwmark => $6,
                :table  => $8
              )
            end
          end
          return all
        end

        def self.add_from_HTTP_request(params)
          params['rules'].each do |rule| # usually just one element
            cmd = 'ip rule add '
            cmd << "prio  #{rule['prio']} "   if rule['prio']   =~ /\S/
            cmd << "from  #{rule['from']} "   if rule['from']   =~ /\S/
            cmd << "to    #{rule['to']} "     if rule['to']     =~ /\S/
            fwmark = compute_fwmark(rule) 
            cmd << "fwmark #{fwmark} "        if fwmark
            cmd << "lookup #{rule['table']} " if rule['table']  =~ /\S/
            msg = System::Command.run cmd, :sudo
            return msg if msg[:err] 
          end
        end

        def self.compute_fwmark(h)
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
