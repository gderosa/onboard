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

=begin

  FWMarking strategy: 32 bit netfilter MARK

  |________| |________| |________| |________|
    unused    in if       out if   DSCP + 00  

  Interfaces are considered also as bridge ports ( iptables -m physdev )

  It's assumed no other is making packet mangling, which would led to 
  unpredictable results...!
  
=end
        def self.compute_fwmark(h)
          mark = 0x00000000
          # in mangle table, MARK rules are not 'final': parsing continues after a match
          if h['iif'] =~ /\S/
            if_mark = nil
            if_mark_already_used = [0]
            physdev_mark = nil
            physdev_mark_already_used = [0]
            # get info...
            `sudo iptables-save -t mangle`.each_line do |line|
              case line
              when /-A PREROUTING -i #{h['iif']} -j MARK --set-xmark 0x(..?)0000\/0xff0000/
                if_mark = $1.to_i(16)
                next
              when /-A PREROUTING -i \S+ -j MARK --set-xmark 0x(..?)0000\/0xff0000/
                if_mark_already_used << $1.to_i(16)
                next
              when /-A PREROUTING -m physdev --physdev-in #{h['iif']} -j MARK --set-xmark 0x(..?)0000\/0xff0000/
                physdev_mark = $1.to_i(16)
                next
              when /-A PREROUTING -m physdev --physdev-in \S+ -j MARK --set-xmark 0x(..?)0000\/0xff0000/
                physdev_mark_already_used << $1.to_i(16)
                next
              end
            end
            if_mark_1st_unused      = if_mark_already_used.max      + 1
            physdev_mark_1st_unused = physdev_mark_already_used.max + 1
            mark                    = [if_mark_1st_unused, physdev_mark_1st_unused].max
            if !if_mark and !physdev_mark 
              msg = System::Command.run "iptables -t mangle -A PREROUTING -i #{h['iif']} -j MARK --set-mark 0x00#{sprintf("%02x", mark)}0000/0x00ff0000", :sudo, :use_exceptions

            end
          end
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
