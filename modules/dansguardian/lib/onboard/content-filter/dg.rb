require 'onboard/extensions/erb'
require 'onboard/content-filter/dg/constants'

class OnBoard
  module ContentFilter
    class DG

      attr_reader :pid, :filtergroups

      def initialize
        reset
      end

      def reset
        @pid = {
          :parent   => nil,
          :children => []
        }
        @filtergroups = []
      end

      def running?
        return false if @pid[:parent] == 0
        return @pid[:parent]
      end

      def root
        CONFDIR
      end

      def config_file
        "#{CONFDIR}/dansguardian.conf"
      end

      def write_all
        dg = self
        ERB::recurse CONFTEMPLATEDIR, binding, '.erb' do |subpath|
          "#{CONFDIR}/#{subpath}" 
        end
      end

      def get_status
        output = `sudo dansguardian -s 2>&1`
        status = $?.dup
        if status == 0
          output =~ /(\d+)/ and @pid[:parent] = $1.to_i
          @pid[:children] = 
              `pidof dansguardian`.split.map{|x| x.to_i} - [@pid[:parent]]
        else
          reset
        end
        @dansguardian_s_string = output
      end

      def get_filtergroups
        Dir.glob "#{CONFDIR}/dansguardianf[0-9]+.conf" do |file|
          puts file
        end
      end

      def start_stop(params)
        if params['start']
          start
        elsif params['stop']
          stop
        elsif params['restart']
          restart
        end
      end

      def start
        System::Command.run "dansguardian -c #{config_file}", :sudo
      end

      def stop
        System::Command.run 'dansguardian -q', :sudo
      end

      def restart
        System::Command.run 'dansguardian -Q', :sudo
      end

    end
  end
end
