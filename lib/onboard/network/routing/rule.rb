require 'facets/hash'
require 'facets/array'

require 'onboard/extensions/string'
require 'onboard/extensions/ipaddr'
require 'onboard/network/interface/ip'

class OnBoard
  module Network
    module Routing
      class Rule

        SAVE_FILE = File.join Routing::CONFDIR, 'rules'

        def self.save
          File.open SAVE_FILE, 'w' do |f|
            f.write `ip rule show`
          end
        end

        def self.restore(opt_h={})
          return false unless File.readable? SAVE_FILE

          # This is critical code. If something goes wrong here your network
          # may break...

          System::Command.run "ip rule flush", :sudo if opt_h[:flush]
          File.foreach SAVE_FILE do |line|
            if line =~ /^\s*(\d+):\s+(\S.*\S)\s*$/
              prio, rulespec = $1, $2
              # next if prio.to_i == 0
                # Yes, rule 0 (lookup local) may have been deleted by misuse
                # of 'ip rule' at the shell, so it definitely makes sense to
                # restore it.
              del = "ip rule del prio #{prio} #{rulespec}"
              add = "ip rule add prio #{prio} #{rulespec}"
	      # Avoid duplicates / make restoring idempotent
              System::Command.run del, :sudo, :try unless opt_h[:flush]
              System::Command.run add, :sudo
            end
          end
        end


        def self.getAll
          all = []
          `ip rule show`.each_line do |line|
            if line =~ /^(\d+):\s+(.*)$/
              rulespec = "prio #{$1} #{$2}"
              if line =~
                  /^(\d+):\s+from\s+(\S+)(\s+to\s+(\S+))?(\s+fwmark\s+(\S+))?(\s+iif\s+(\S+))?\s+(lookup|table)\s+(\S+)/
                prio, from, to, fwmark_and_fwmask, iif, table =
                    $1, ($2 || 'all'), ($4 || 'all'), $6, $8, $10
                if fwmark_and_fwmask =~ /^([^\/]+)\/([^\/]+)$/
                  fwmark, fwmask = $1, $2
                else
                  fwmark, fwmask = fwmark_and_fwmask, '0xffffffff'
                end
                all << self.new(
                  :prio     => prio,
                  :from     => from,
                  :to       => to,
                  :fwmark   => fwmark,
                  :fwmask   => fwmask,
                  :iif      => iif,
                  :table    => table,
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
            h = compute_fwmark!(rule)
            fwmark = h[:mark]
            fwmask = h[:mask]
            cmd << "fwmark #{fwmark}/#{fwmask} " if fwmark and fwmark > 0
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

          # explicit deletion, i.e. from an explicit deletion request, not as a
          # consequence of a *change* request
          deleted_indexes         = []
          new_rules_params.each_with_index do |rule_params, idx|
            if rule_params['delete'] == 'on'
              old_rules[idx].del!
              deleted_indexes << idx
            end
          end
          old_rules.delete_values_at        *deleted_indexes
          new_rules_params.delete_values_at *deleted_indexes
          new_rules.delete_values_at        *deleted_indexes

          # Change request

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

        end

=begin

  FWMarking strategy: 32 bit netfilter MARK

  |________| |________| |________| |________|
   unused/0   iphysdev   unused/0   DSCP + 00  # physdev = bridge port

  It's assumed no other is making packet mangling, which would led to
  unpredictable results...!

=end

        # TODO TODO TODO: rename h -> rule_h (more meaningful and less bug-prone)
        def self.compute_fwmark!(h)
          return_h = {
            :mark => 0x00000000,
            :mask => 0x00000000
          }

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

          retval_mark = 0x00000000 # 32 bits fw mark
          retval_mask = 0x00000000

          computed_mark.each_pair do |match_by, val|
            orig    = retval_mark
            mask    = config[match_by][:fwmark][:mask]

            # if the rule (h) is on iphysdev AND dscp
            # retval_mask will be 0x00ff00ff ;
            # if the rule is on dscp only
            # retval_mask will be 0x000000ff ;
            # if the rule is on iphysdev only
            # retval_mask will be 0x00ff0000 .
            retval_mask |= mask if (h[match_by.to_s] =~ /\S/ or h[match_by.to_s].to_i > 0)

            set     = val << config[match_by][:fwmark][:bitshift]
            # bitwise mask ? set : orig
            retval_mark  = (mask & set) | ( (0xffffffff - mask) & orig )
          end

          return_h[:mark] = retval_mark
          return_h[:mask] = retval_mask

          return return_h
        end

=begin
        def self.delete_rules_by_fwmark(h)
           select_rules_by_fwmark(h).map{|x| x.del!}
        end

        def self.select_rules_by_fwmark(h)
          getAll.select{|x| x.fwmark_match(h)}
        end
=end

        attr_reader :prio, :from, :to, :table, :fwmark, :fwmask, :iif, :iphysdev, :dscp, :rulespec

        def initialize(h_in)
          h = h_in.symbolize_keys
          @prio     = h[:prio]
          @from     = h[:from]
          @from.strip! if @from.respond_to? :strip!
          @to       = h[:to]
          @table    = h[:table]
          @fwmark   = h[:fwmark]
          @fwmask   = h[:fwmask]
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
        alias to_h data

        def to_json(*a); to_h.to_json(*a); end
        def to_yaml(*a); to_h.to_yaml(*a); end

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
