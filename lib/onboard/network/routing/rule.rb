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
   unused/0    in if      out if    DSCP + 00  

  Interfaces are considered also as bridge ports ( iptables -m physdev )

  It's assumed no other is making packet mangling, which would led to 
  unpredictable results...!
  
=end
        def self.compute_fwmark(h)
          mark_iif, mark_oif, mark_dscp = 0x00, 0x00, 0x00
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
            new_mark                = [if_mark_1st_unused, physdev_mark_1st_unused].max
            if 
                if_mark.kind_of?      Integer and 
                physdev_mark.kind_of? Integer and 
                if_mark >             0       and  
                physdev_mark >        0       and 
                if_mark ==            physdev_mark

              mark_iif = if_mark

            else # Now, mangle the mangle table ;-)
              System::Command.run "iptables -t mangle -D PREROUTING -i #{h['iif']} -j MARK --set-mark 0x00#{sprintf("%02x", if_mark)}0000/0x00ff0000", :sudo, :raise_exception if if_mark
              System::Command.run "iptables -t mangle -D PREROUTING -m physdev --physdev-in #{h['iif']} -j MARK --set-mark 0x00#{sprintf("%02x", physdev_mark)}0000/0x00ff0000", :sudo, :raise_exception if physdev_mark
              System::Command.run "iptables -t mangle -A PREROUTING -i #{h['iif']} -j MARK --set-mark 0x00#{sprintf("%02x", new_mark)}0000/0x00ff0000", :sudo, :raise_exception
              System::Command.run "iptables -t mangle -A PREROUTING -m physdev --physdev-in #{h['iif']} -j MARK --set-mark 0x00#{sprintf("%02x", new_mark)}0000/0x00ff0000", :sudo, :raise_exception
              mark_iif = new_mark
            end
          end
          return sprintf("00%02x%02x%02x", mark_iif, mark_oif, mark_dscp)
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
