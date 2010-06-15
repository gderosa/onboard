require 'facets/hash'

require 'onboard/network/interface/ip'

require 'onboard/extensions/string'
require 'onboard/extensions/ipaddr'

class OnBoard
  module Network
    module Routing
      class Rule

        def self.getAll
          all = []
          `ip rule show`.each_line do |line|
            if line =~ /^(\d+):\s+(.*)$/
              rulespec = "prio #{$1} #{$2}"
              if line =~ 
                  /^(\d+):\s+from\s+(\S+)(\s+to\s+(\S+))?(\s+fwmark\s+(\S+))?(\s+iif\s+(\S+))?\s+(lookup|table)\s+(\S+)/
                #puts line
                all << self.new(
                  :prio     => $1,
                  :from     => ($2 || 'all'),
                  :to       => ($4 || 'all'),
                  :fwmark   => $6,
                  :iif      => $8,
                  :table    => $10,
                  :rulespec => rulespec
                )
              end
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
            cmd << "iif   #{rule['iif']} "    if rule['iif']    =~ /\S/
            fwmark = compute_fwmark!(rule) 
            cmd << "fwmark #{fwmark} "        if fwmark and fwmark > 0
            cmd << "lookup #{rule['table']} " if rule['table']  =~ /\S/
            msg = System::Command.run cmd, :sudo
            return msg if msg[:err] 
          end
        end

        def self.change_from_HTTP_request(h)
          old_rules               = h[:current_rules]
          new_rules_params        = h[:http_params]['rules']
          new_rules               = new_rules_params.map{|h| self.new(h)} 

          rules_to_del            = []
          rules_to_add_params     = []

          new_rules_params.dup.each_with_index do |rule_params, idx|
            if rule_params['delete'] == 'on'
              old_rules[idx].del!
              old_rules.delete_at idx
              new_rules_params.delete_at idx
              new_rules.delete_at idx
            end
          end

          new_rules.each_with_index do |new_rule, n|
            unless old_rules.include? new_rule
              rules_to_add_params << new_rules_params[n] 
            end
          end

          old_rules.each do |old_rule|
            unless new_rules.include? old_rule
              rules_to_del << old_rule
            end
          end

          # add only the rules wich are really new
          add_from_HTTP_request('rules' => rules_to_add_params)

          # delete rules which are no longer present
          rules_to_del.map{|rule| rule.del!}

=begin # DEBUG
          puts '---'
          pp rules_to_add_params
          pp rules_to_del
=end

=begin # DEBUG
# should print an identity matrix if no chenges are requested from html form 
          puts
          old_rules.each do |old_rule|
            puts
            new_rules.each do |new_rule|
              if old_rule == new_rule
                print '1'
              else
                print '0'
              end
            end
          end
=end
        end

=begin

  FWMarking strategy: 32 bit netfilter MARK

  |________| |________| |________| |________|
   unused/0   iphysdev   unused/0   DSCP + 00  # physdev = bridge port

  It's assumed no other is making packet mangling, which would led to 
  unpredictable results...!
  
=end
        def self.compute_fwmark!(h)

          computed_mark = {
            :iphysdev   => 0x00,
            :dscp       => 0x00
          }

          # TODO: Don't play with iptables here. Create useful methods under
          # Network::Iptables namespace, instead. And use it!

          config = {
            :iphysdev => { # input bridge port
              :value                      => h['iphysdev'], # same as iif...
              :ipt_switch                 => "-m physdev --physdev-in",
              :fwmark                     => {
                :regex                      => '0x(\h?\h)0000',
                :mask                       => 0xff0000,
                :mask_str                   => '0xff0000',
                :bitshift                   => 16 # two bytes
              }, # same as above...
            },             
            :dscp => { # DiffServ Code Points
              :value                      => h['dscp'].to_i,
              :ipt_switch                 => "-m dscp --dscp",
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

          [:iphysdev, :dscp].each do |match_by|

            detected_mark_others[match_by] ||= [] # initialize as empty Array
            value         = config[match_by][:value] 
                # iterface name, dscp value etc.
              
            next if value.kind_of? Integer  and value == 0
            next if value.kind_of? String   and value =~ /^\s*$/
              
            ipt_switch    = config[match_by][:ipt_switch]              
            ipt_match     = "#{ipt_switch} #{value}"
            ipt_match_any = "#{ipt_switch} (\\S+)"
            fwmark        = config[match_by][:fwmark]
            regex         = fwmark[:regex]
            mask_str      = fwmark[:mask_str]
            bitshift      = fwmark[:bitshift]

            `sudo iptables-save -t mangle`.each_line do |line|

              re = 
/-A PREROUTING #{ipt_match} .*-j MARK --set-xmark #{regex}\/#{mask_str}/
              re_any =
/-A PREROUTING #{ipt_match_any} .*-j MARK --set-xmark #{regex}\/#{mask_str}/

#NOTE: ipt_match_any contains a capture, while ipt_match not

              if line =~ re
                detected_mark[match_by] = $1.to_i(16)
              elsif line =~ re_any
                if value == $1.to_i and value.kind_of? Integer
                  detected_mark[match_by] = $2.to_i(16)
                else
                  detected_mark_others[match_by] << $2.to_i(16)
                end
              end

            end

            if 
                detected_mark[match_by].kind_of?  Integer and 
                detected_mark[match_by] >         0               

              computed_mark[match_by] = detected_mark[match_by]

            else 

              if match_by == :dscp # DSCP is special, no need to create a "map"

                computed_mark[match_by] = (value.to_i << 2) 
                # DS FIELD bits = DSCP(6 bits) + ECN(2 bits)
                # fw mark "byte" will be identical to a DS field with ECN bits
                # set to zero, hence the bitshift "<< 2" 
                #
                # Last two bits will be used when a ECN match will be 
                # desired/implemented, so they are reserved for future use.

              else
                # find the first available mark
                computed_mark[match_by] = ( 
                    (0x01..0xff).to_a               - 
                    detected_mark_others[match_by]   
                ).min
              end

              shifted_mark = computed_mark[match_by] << bitshift
              set_mark = "0x#{shifted_mark.to_s(16)}/0x#{fwmark[:mask].to_s(16)}"  
              comment = "-m comment --comment \"automatically added by #{self.name}\"" 
              
              System::Command.run "iptables -t mangle -A PREROUTING #{ipt_match} -j MARK --set-mark #{set_mark} #{comment}", :sudo, :raise_exception
            end

          end

          retval = 0x00000000 # 32 bits fw mark
          computed_mark.each_pair do |match_by, val|
            # bitwise mask ? set : orig
            orig    = retval
            mask    = config[match_by][:fwmark][:mask]
            set     = val << config[match_by][:fwmark][:bitshift]
            retval  = (mask & set) | ( (0xffffffff - mask) & orig )
          end
          return retval

        end

=begin
        def self.delete_rules_by_fwmark(h)
           select_rules_by_fwmark(h).map{|x| x.del!}  
        end

        def self.select_rules_by_fwmark(h)
          getAll.select{|x| x.fwmark_match(h)} 
        end
=end

        attr_reader :prio, :from, :to, :table, :fwmark, :iif, :iphysdev, :dscp, :rulespec

        def initialize(h_in)
          h = h_in.symbolize_keys
          @prio     = h[:prio]
          @from     = h[:from]
          @from.strip! if @from.respond_to? :strip!
          @to       = h[:to]
          @table    = h[:table]
          @fwmark   = h[:fwmark]
          @iif      = h[:iif]
          @rulespec = h[:rulespec] 

          if @fwmark # object comes from the OS
            info      = find_info_from_fwmark
            @iphysdev = info[:iphysdev]
            @dscp     = info[:dscp]
          else # object may come from an HTML form
            @iphysdev = h[:iphysdev]
            @dscp     = h[:dscp ]
          end
        end

        def del!
          System::Command.run(
            "ip rule del #{@rulespec}",
            :sudo,
            :raise_exception
          )
        end

        def ==(other)
          return true if (
              (
                @from == other.from or 
                (
                  Interface::IP.valid_address? @from and
                  Interface::IP.valid_address? other.from and
                  IPAddr.new(@from) == IPAddr.new(other.from)
                )
              ) and
              (
                @fwmark.to_i == other.fwmark.to_i or
                (
                  @dscp.to_i == other.dscp.to_i and
                  @iphysdev.to_s.strip  == other.iphysdev.to_s.strip
                )
              ) and
              @iif.to_s.strip == other.iif.to_s.strip and
              @prio.to_i == other.prio.to_i and
              Table.number(@table) == Table.number(other.table)  # and ignore @to ;)
          )
          return false
        end

        def data
          {
            'prio'      => @prio,
            'from'      => @from,
            'to'        => @to,
            'table'     => @table,
            'iif'       => @iif,
            'iphysdev'  => @iphysdev,
            'dscp'      => @dscp
          }
        end

        def find_info_from_fwmark

          retval = {
            :dscp     => nil,
            :iphysdev => nil
          }

          return retval unless @fwmark.to_i > 0

          `sudo iptables-save -t mangle`.each_line do |line|

            if line =~ /-m dscp .*--dscp (\S+) .*-j MARK .*--set-x?mark (0x\h+)\/(0x\h+)/
              detected = {
                :dscp => $1.to_i,
                :mark => $2.to_i,
                :mask => $3.to_i
              }

              if (@fwmark.to_i & detected[:mask]) == (detected[:mark] & detected[:mask]) 
                retval[:dscp] = detected[:dscp] 
              end
            end

            if line =~ 
/-m physdev .*--physdev-in (\S+) .*-j MARK .*--set-x?mark (0x\h+)\/(0x\h+)/
              detected = {
                :iphysdev => $1,
                :mark     => $2.to_i,
                :mask     => $3.to_i
              }

              if (@fwmark.to_i & detected[:mask]) == (detected[:mark] & detected[:mask]) 
                retval[:iphysdev] = detected[:iphysdev] 
              end
            end

          end

          return retval

        end

      end
    end
  end
end
