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
   unused/0    in if     unused/0   DSCP + 00  # "out if" makes no sense...

  Interfaces are considered also as bridge ports ( iptables -m physdev )

  It's assumed no other is making packet mangling, which would led to 
  unpredictable results...!
  
=end
        def self.compute_fwmark!(h)

          computed_mark = {
            :iif        => 0x00,
            :iphysdev   => 0x00,
            :dscp       => 0x00
          }

          # TODO: place elsewhere?
          config = {
            :iif  => { # input interface
              :skip                       => not(h['iif'] =~ /\S/) 
              :ipt_match                  => "-i #{h['iif']}",
              ipt_match_any              => "-m physdev --physdev-in \S+",
              :fwmark                     => {
                :regex                      => '0x(\h?\h)0000',
                :mask                       => 0xff0000,
                :mask_str                   => '0xff0000',
                :bitshift                   => 16 # two bytes
              }
            },
            :iphysdev => { # input bridge port
              :skip                       => not(h['iif'] =~ /\S/) # same as above...
              :ipt_match                  => "-m physdev --physdev-in #{h['iif']}",
              :ipt_match_any              => "-m physdev --physdev-in \S+",
              :fwmark                     => {
                :regex                      => '0x(\h?\h)0000',
                :mask                       => 0xff0000,
                :mask_str                   => '0xff0000',
                :bitshift                   => 16 # two bytes
              } # same as above...
            },             
            :dscp => { # DiffServ Code Points
              :skip                       => not(h['dscp'] =~ /\S/)
              :ipt_match                  => "-m dscp --dscp 0x#{h['dscp'].to_s(16)}",
              :ipt_match_any              => "-m dscp --dscp 0x\S+",
              :fwmark                     => {
                :regex                      => '0x(\h?\h)',
                :mask                       => 0xff,
                :mask_str                   => '0xff',
                :bitshift                   => 0 # last byte
              }             
            }            
          }

          detected_mark         = {}
          detected_mark_others  = {}

          `sudo iptables-save -t mangle`.each_line do |line|

            [:iif, :iphysdev, :dscp].each do |match_by|

              next if config[match_by][:skip]

              ipt_match = config[match_by][:ipt_match]
              regex     = config[match_by][:regex]
              mask_str  = config[match_by][:mask_str]

              case line
              when /-A PREROUTING #{ipt_match} .*-j MARK --set-xmark #{regex}\/#{mask_str}/
                detected_mark[match_by] = $1.to_i(16)
                next
              when /-A PREROUTING #{ipt_match_any} .*-j MARK --set-xmark #{regex}\/#{mask_str}/
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
