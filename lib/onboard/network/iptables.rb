class OnBoard
  module Network
    class Iptables
      def self.add_rule_from_HTTP_request(params)

        all_bridge_ports = []

        # you might receive something like
        #
        #   params['bridge_ports'] #=> ['eth1', 'eth2', 'eth3']
        #
        # regardless which bridge they belong; or something like
        #
        #   params['bridges'] #=> {'br0' => ['eth1', 'eth2'], 'br1' => ['eth3']}
        #

        if params['bridge_ports'].respond_to? :[]
          all_bridge_ports = params['bridge_ports']
        elsif params['bridges'].respond_to? :each_value
          params['bridges'].each_value do |br|
            all_bridge_ports << br['ports']
          end
        end

        str = ""
        str << case params['version']
        when '4'
          'iptables '
        when '6'
          'ip6tables '
        else
          raise ArgumentError,
              "IP version must be 4 or 6, got #{params['version']}"
        end
        str << '-t '                  << params['table']            << ' ' if
            params['table'] =~ /\S/
        str <<              params['append_insert']                 << ' '
        str <<              params['chain']                         << ' '
        str << '-j '                  << params['jump-target']      << ' '
        if params['jump-target'] =~ /LOG/
          # add some reasonable defaults to avoid DOS attacks...
          # TODO?: do not hardcode, allow user's choice?
          str <<
              '-m state --state NEW,UNTRACKED,INVALID ' <<
              '-m limit --limit 6/minute --limit-burst 10 '
        end
        str << "-m comment --comment \"#{params['comment']}\" " if
            params['comment'] and params['comment'] =~ /\S/
        str << "-p "                  << params['proto']            << ' ' if
            params['proto']         =~ /\S/

        %w{in out}.each do |inout|
          if params["#{inout}put_iface"]   =~ /\S/
            if all_bridge_ports.include? params["#{inout}put_iface"]
              str << "-m physdev --physdev-#{inout} " << params["#{inout}put_iface"] << ' '
            else
              str << "-#{inout[0]} " << params["#{inout}put_iface"] << ' '
            end
          end
        end

        str << "-s "                  << params["source_addr"]      << ' ' if
            params["source_addr"]   =~ /\S/
        str << "-d "                  <<   params["dest_addr"]      << ' ' if
            params["dest_addr"]     =~ /\S/
        str << "--sport "             <<  params["source_ports"]    << ' ' if
            params["source_ports"]  =~ /\S/
        str << "--dport "             << params["dest_ports"]       << ' ' if
            params["dest_ports"]    =~ /\S/
        str << "-m mac --mac-source " << params["mac_source"]       << ' ' if
            params["mac_source"]    =~ /\S/
        str << "-m state --state "    << params["state"].join(",")  << ' ' if
            params["state"].respond_to? :join and params["state"].length > 0
        if params['jump-target'] == 'REDIRECT'
          str << "--to-ports " << params['to-destination_port']
        else
          if params['to-destination_addr'] =~ /\S/ or params['to-destination_port'] =~ /\S/
            str << "--to-destination " << params['to-destination_addr'].strip
            if params['to-destination_port'] =~ /\S/
              str << ':' << params['to-destination_port']
            else
              str << ' '
            end
          end
          if params['to-source_addr'] =~ /\S/ or params['to-source_port'] =~ /\S/
            str << "--to-source " << params['to-source_addr'].strip
            if params['to-source_port'] =~ /\S/
              str << ':' << params['to-source_port']
            else
              str << ' '
            end
          end
        end
        msg = OnBoard::System::Command.run str, :sudo
        return msg
      end

      def self.del_rule_from_HTTP_request(params)
        str = ""
        str << case params['version'] # TODO: DRY DRY DRY DRY !!!
        when '4'
          'iptables '
        when '6'
          'ip6tables '
        else
          raise ArgumentError,
              "IP version must be 4 or 6, got #{params['version']}"
        end
        str << '-t '      << params['table']         << ' ' if
            params['table'] =~ /\S/
        str << ' -D '     << params['chain']         << ' ' << params['rulenum']
        msg = OnBoard::System::Command.run str, :sudo
        return msg
      end

      def self.get_rulespec(h)
        iptablesobj = OnBoard::Network::Iptables.new(
          :ip_version => h[:ip_version] || '4',
          :tables     => [h[:table]]
        )
        iptablesobj.get_all_info
        return iptablesobj.tables[h[:table]].chains[h[:chain]].rulespecs[h[:rulenum].to_i - 1]
      end

      def self.move_rule_from_HTTP_request(params, position)
        rulespec = params['rulespec'] || get_rulespec(
          :table    => params['table'],
          :chain    => params['chain'],
          :rulenum  => params['rulenum']
        )
        msg = del_rule_from_HTTP_request(params)  # DEVEL DEBUG
        return msg if msg.respond_to? :[] and not msg[:ok]
        str = ""
        str << case params['version']
        when '4'
          'iptables '
        when '6'
          'ip6tables '
        else
          raise ArgumentError,
              "IP version must be 4 or 6, got #{params['version']}"
        end
        str << '-t '      << params['table']         << ' ' if
            params['table'] =~ /\S/
        str << '-I ' << params['chain'] << ' ' << position << ' ' << rulespec
        return OnBoard::System::Command.run str, :sudo
      end

      def self.move_rule_up_from_HTTP_request(params)
        return move_rule_from_HTTP_request(params, (params['rulenum'].to_i - 1).to_s)
      end

      def self.move_rule_down_from_HTTP_request(params)
        return move_rule_from_HTTP_request(params, (params['rulenum'].to_i + 1).to_s)
      end

      def self.save
        ['iptables', 'ip6tables'].each do |ipt|
          cmdstr = ''
          cmdstr << ipt << '-save > ' << OnBoard::CONFDIR << '/network/' <<
              ipt << '.save'
          OnBoard::System::Command.run cmdstr, :sudo
        end
      end

      def self.restore
        ['iptables', 'ip6tables'].each do |ipt|
          file = OnBoard::CONFDIR + '/network/' + ipt + '.save'
          cmdstr = ''
          cmdstr << ipt << '-restore < ' << file
          OnBoard::System::Command.run cmdstr, :sudo if File.exists? file
        end
      end

      # Instance methods

      attr_reader :tables, :ip_version, :cmd

      def initialize(h)
        @ip_version = h[:ip_version].to_i
        @cmd = case @ip_version
               when 4
                 'iptables'
               when 6
                 'ip6tables'
               else
                 'iptables'
               end
        @tables = {}
        h[:tables] = %w{filter nat mangle raw} unless h[:tables]
        # when creating a new Iptables object, client code may restrict
        # OS querying to specific tables
        h[:tables].each do |tablename|
          @tables[tablename] = Table.new(:name =>tablename)
        end
      end

      def get_all_info
        @tables.each_pair do |tablename, table|
          parse_iptables_L(
            :tablename  => tablename,
            :cmd        => @cmd
          )
        end
        @tables.each_pair do |tablename, table|
          grab_rule_specs(
            :tablename  => tablename,
            :cmd        => @cmd
          )
        end
      end

      # NOTE: this must be called BEFORE grab_rule_specs, not after.
      # parse_iptables_L does not check if tables/chains already exists,
      # but always reset data. TODO: check for already existent tables/chains
      def parse_iptables_L(h)
        tablename = h[:tablename]
        iptablescmd = h[:cmd]
        raise ArgumentError, "Table #{tablename} does not exists" unless
            %w{filter nat mangle raw}.include? tablename
        previous_line_was_new_chain = false
        rulenum = 0
        chain = nil
        table = @tables[tablename] = Table.new(:name => tablename)
        `sudo #{iptablescmd} -L -n -v -t #{tablename}`.each_line do |line|
          line.force_encoding 'utf-8'
          if line =~ /^Chain\s(\S+)/
            chainname = $1
            chain = table.chains[chainname] = Chain.new(:name => chainname)
            rulenum = 0
            previous_line_was_new_chain = true
          elsif previous_line_was_new_chain
            chain.rules = []
            chain.listfields = ['#'] + line.strip.split(/\s+/) + ['misc']
            # iptables -L -n -v fields are:
            # [0] 1    2     3      4    5   6  7   8      9           [10]
            # [#] pkts bytes target prot opt in out source destination [misc]


            previous_line_was_new_chain = false
          elsif line =~ /\S/
            number_of_fields = 10
            rulenum += 1
            rule_ary = [rulenum] + line.strip.split(/\s+/, number_of_fields)

            # Mainly with ip6tables, the 'opt' field may be made up of
            # spaces only: this confuses line.strip.split(/\s+/),
            # so let's try to guess if rule_ary[5] has got
            # the 'in' field instead of 'opt'
            #
            # NOTE: It's assumed the options in the opt field MUST begin
            # with '-' NOTE: iptables(IPv4) gives '--' when no options
            opt = rule_ary[5]
            rule_ary.insert(5, '--') unless opt =~ /^-/

            # pad the end of the array if it's shorter than number_of_fields
            # i.e. the '[misc]' field is missing
            if rule_ary.length < number_of_fields + 1
              (number_of_fields + 1 - rule_ary.length).times do
                rule_ary << "--"
              end
            end

            # Sometimes you may have the opposite problem....
            if rule_ary.length > number_of_fields + 1
              newstr = rule_ary[number_of_fields..-1].join(' ')
              rule_ary[number_of_fields] = newstr
              while rule_ary.length > number_of_fields + 1
                rule_ary.pop
              end
            end


            # NOTE: there are a 'opt' and a '[misc]' field, they are not the
            # same, and this may confuse you :-(

            # TODO TODO TODO: get rid of messy iptables -L output and rely
            # on iptables[6]-save only  ?

            chain.rules << rule_ary
                # Array of Array
            previous_line_was_new_chain = false
          end
        end
      end

      def grab_rule_specs(h)
        tablename = h[:tablename]
        iptablescmd = h[:cmd]
        raise ArgumentError, "Table #{tablename} does not exists" unless
            %w{filter nat mangle raw}.include? tablename
        table = @tables[tablename] = Table.new(:name => tablename) \
            unless table = @tables[tablename] # create new if it doesn't exist
        `sudo #{iptablescmd}-save -t #{tablename}`.each_line do |line|
          line.force_encoding 'utf-8'
          if line =~ /^-A\s+(\S+)\s+(.*)$/
            chainname = $1
            rulespec = $2
            chain = table.chains[chainname] = Chain.new(:name => chainname) \
                unless chain = table.chains[$1] # create new if it doesn't exist
            chain.rulespecs << rulespec
          end
        end
      end

      def data
        h = {}
        @tables.each_pair do |tablename, table|
          h[tablename] = table.data
        end
        return h
      end
      alias to_h data

      def to_json(*a); to_h.to_json(*a); end
      def to_yaml(*a); to_h.to_yaml(*a); end

      class Table
        attr_accessor :chains
        def initialize(h)
          @name = h[:name]
          @chains = {}
        end
        def data
          h = {}
          @chains.each_pair do |chainname, chain|
            h[chainname] = chain.data
          end
          {
            'name' => @name,
            'chains' => h
          }
        end
      end

      class Chain
        attr_reader :name
        attr_accessor :listfields, :rules, :rulespecs
        def initialize(h)
          @name = h[:name]
          @listfields = []
          @rules = []
          @rulespecs = []
        end
        def data
          {
            'name' => @name,
            'listfields' => @listfields,
            'rules' => @rules,
            'rulespecs' => @rulespecs
          }
        end
      end

    end
  end
end

if $0 == __FILE__
  require 'pp'
  iptables = OnBoard::Network::Iptables.new
  iptables.parse_iptables_L('filter')
  pp iptables
end
