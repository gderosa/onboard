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
                :fwmark => ($6 || '0x00000000'),
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
            fwmark = compute_fwmark!(rule) 
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
        def self.compute_fwmark!(h)
          mark_iif, mark_oif, mark_dscp = 0x00, 0x00, 0x00
          # in mangle table, MARK rules are not 'final': parsing continues after a match
          if h['iif'] =~ /\S/
            detected_if_mark              = nil
            detected_if_mark_others       = [0]
            detected_physdev_mark         = nil
            detected_physdev_mark_others  = [0]
            # get info...
            `sudo iptables-save -t mangle`.each_line do |line|
              case line
                # ".*" in regexes refer to possible comments 
                # e.g. "-m comment --comment ...", or other things...
              when /-A PREROUTING -i #{h['iif']}.*-j MARK --set-xmark 0x(..?)0000\/0xff0000/
                detected_if_mark = $1.to_i(16)
                next
              when /-A PREROUTING -i \S+.*-j MARK --set-xmark 0x(..?)0000\/0xff0000/
                detected_if_mark_others << $1.to_i(16)
                next
              when /-A PREROUTING -m physdev --physdev-in #{h['iif']}.*-j MARK --set-xmark 0x(..?)0000\/0xff0000/
                detected_physdev_mark = $1.to_i(16)
                next
              when /-A PREROUTING -m physdev --physdev-in \S+.*-j MARK --set-xmark 0x(..?)0000\/0xff0000/
                detected_physdev_mark_others << $1.to_i(16)
                next
              end
            end

            if 
                detected_if_mark.kind_of?      Integer       and 
                detected_physdev_mark.kind_of? Integer       and 
                detected_if_mark >             0             and  
                detected_physdev_mark >        0             and 
                detected_if_mark ==            detected_physdev_mark

              mark_iif = detected_if_mark

            else # Now, mangle the mangle table ;-)

              # delete routing rules and firewall marks which are not compliant 
              # with our "policy"
              #
              # NOTE: this code is untested for the cases when it actually delete
              # something....

              if detected_if_mark
                System::Command.run "iptables -t mangle -D PREROUTING -i #{h['iif']} -j MARK --set-mark 0x00#{sprintf("%02x", detected_if_mark)}0000/0x00ff0000", :sudo, :raise_exception if detected_if_mark
                delete_rules_by_fwmark(:mark => detected_if_mark << 2*8, :mask => 0x00ff0000)
              end
              if detected_physdev_mark
                System::Command.run "iptables -t mangle -D PREROUTING -m physdev --physdev-in #{h['iif']} -j MARK --set-mark 0x00#{sprintf("%02x", detected_physdev_mark)}0000/0x00ff0000", :sudo, :raise_exception if detected_physdev_mark
                delete_rules_by_fwmark(:mark => detected_physdev_mark << 2*8, :mask => 0x00ff0000)
              end

              # find the first available mark
              p detected_if_mark_others       # DEBUG
              p detected_physdev_mark_others  # DEBUG
              new_mark = ( 
                  (0x01..0xff).to_a             - 
                  detected_if_mark_others       - 
                  detected_physdev_mark_others
              ).min

              comment = " -m comment --comment \"automatically added by #{self.name}\" " 
              System::Command.run "iptables -t mangle -A PREROUTING -i #{h['iif']} -j MARK --set-mark 0x00#{sprintf("%02x", new_mark)}0000/0x00ff0000 #{comment}", :sudo, :raise_exception
              System::Command.run "iptables -t mangle -A PREROUTING -m physdev --physdev-in #{h['iif']} -j MARK --set-mark 0x00#{sprintf("%02x", new_mark)}0000/0x00ff0000 #{comment}", :sudo, :raise_exception
           end
          end
          return sprintf("00%02x%02x%02x", mark_iif, mark_oif, mark_dscp)
        end

        def self.delete_rules_by_fwmark(h)
           select_rules_by_fwmark(h).map{|x| x.del!}  
        end

        def self.select_rules_by_fwmark(h)
          getAll.select{|x| x.fwmark_match(h)} 
        end

        attr_reader :prio, :from, :to, :table, :fwmark

        def initialize(h)
          @prio   = h[:prio]
          @from   = h[:from]
          @to     = h[:to]
          @table  = h[:table]
          @fwmark = h[:fwmark]
        end

        def del!
          System::Commad.run(
              "ip rule del prio #@prio from #@from to #@to fwmark #@fwmark", 
              :sudo, :raise_exception
          )
        end

        # matches if @fwmark == '0x1234abcd' and 
        # h == {:mark => 0x0000ab00, :mask => 0x0000ff00}
        def fwmark_match(h)
          (@fwmark.to_i(16) | h[:mask]) == h[:mark]
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
