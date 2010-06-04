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

          computed_mark = {
            :iif  => 0x00,
            :oif  => 0x00,
            :dscp => 0x00
          }

          # TODO: place elsewhere?
          configuration = {
            :iif  => { # input interface, also as a brige port
              :name                       => h['iif'],
              :ipt_if_switch              => '-i',
              :ipt_physdev_switch         => '-m physdev --physdev-in',
              :fwmark                     => {
                :regex                      => '0x(\h?\h)0000',
                :mask                       => 0xff0000,
                :mask_str                   => '0xff0000',
                :bitshift                   => 16 # two bytes
              }
            },
# This doesn't make sense: to know the output interface we should already have been
# made the routing decision... :-P
=begin              
            :oif => { # output interface, also as a brige port
              :name                       => h['oif'],
              :ipt_if_switch              => '-o',
              :ipt_physdev_switch         => '-m physdev --physdev-out',
              :fwmark                     => {
                :regex                      => '0x(\h?\h)00',
                :mask                       => 0xff00,
                :mask_str                   => '0xff00',
                :bitshift                   => 8 # one byte
              }             
            },
=end
            :dscp => { # DiffServ Code Points
              :ipt_switch                 => '-m dscp --dscp',
              :fwmark                     => {
                :regex                      => '0x(\h?\h)',
                :mask                       => 0xff,
                :mask_str                   => '0xff',
                :bitshift                   => 0 # last byte
              }             
            }            
          }

          if_name             = configuration[:iif][:name]
          ipt_if_switch       = configuration[:iif][:ipt_if_switch]
          ipt_physdev_switch  = configuration[:iif][:ipt_physdev_switch]
          fwmark              = configuration[:iif][:fwmark]

          if if_name =~ /\S/
            detected_if_mark              = nil
            detected_if_mark_others       = [0]
            detected_physdev_mark         = nil
            detected_physdev_mark_others  = [0]
            # get info...
            `sudo iptables-save -t mangle`.each_line do |line|
              case line
                # ".*" in regexes refer to possible comments 
                # e.g. "-m comment --comment ...", or other things...
              when /-A PREROUTING #{ipt_if_switch} #{if_name}.*-j MARK --set-xmark #{fwmark[:regex]}\/#{fwmark[:mask_str]}/
                detected_if_mark = $1.to_i(16)
                next
              when /-A PREROUTING #{ipt_if_switch} \S+.*-j MARK --set-xmark #{fwmark[:regex]}\/#{fwmark[:mask_str]}/
                detected_if_mark_others << $1.to_i(16)
                next
              when /-A PREROUTING #{ipt_physdev_switch} #{if_name}.*-j MARK --set-xmark #{fwmark[:regex]}\/#{fwmark[:mask_str]}/
                detected_physdev_mark = $1.to_i(16)
                next
              when /-A PREROUTING #{ipt_physdev_switch} \S+.*-j MARK --set-xmark #{fwmark[:regex]}\/#{fwmark[:mask_str]}/
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

              computed_mark[:iif] = detected_if_mark

            elsif
                detected_if_mark != detected_physdev_mark
              raise RuntimeError, "Found inconsistence in fw marking!"
            else 

              # find the first available mark
              computed_mark[:iif] = ( 
                  (0x01..0xff).to_a             - 
                  detected_if_mark_others       - 
                  detected_physdev_mark_others
              ).min

              shifted_mark = computed_mark[:iif] << fwmark[:bitshift] 

              set_mark = "0x#{shifted_mark.to_s(16)}/0x#{fwmark[:mask].to_s(16)}"  
              comment = "-m comment --comment \"automatically added by #{self.name}\"" 

              System::Command.run "iptables -t mangle -A PREROUTING #{ipt_if_switch} #{if_name} -j MARK --set-mark #{set_mark} #{comment}", :sudo, :raise_exception
              System::Command.run "iptables -t mangle -A PREROUTING #{ipt_physdev_switch} #{if_name} -j MARK --set-mark #{set_mark} #{comment}", :sudo, :raise_exception
            end

          end
          
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
