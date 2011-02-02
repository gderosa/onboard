require 'onboard/extensions/erb'
require 'onboard/content-filter/dg/constants'

class OnBoard
  module ContentFilter
    class DG

      autoload :FilterGroup, 'onboard/content-filter/dg/filtergroup'

      attr_reader :pid, :filtergroups

      def initialize
        reset
      end

      def reset
        @pid = {
          :parent   => nil,
          :children => []
        }
        @filtergroups = {}
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
        @filtergroups = {}

        # Filter Group abstraction
        Dir.glob "#{CONFDIR}/filtergroups/*" do |filepath|
          if filepath =~ /([^\.\/\\]+)\.conf$/ 
            id = $1
            @filtergroups[id] = FilterGroup.new(
              :conffile         => filepath,
              :id               => id,
              :dansguardian_id  => nil 
            )
          end
        end

        # DansGuardian Filter Groups
        Dir.glob "#{CONFDIR}/dansguardianf*.conf" do |filepath|
          if filepath =~ /dansguardianf(\d+)\.conf$/
            dansguardian_id = $1.to_i
            if File.symlink? filepath
              id = File.basename(
                  File.readlink(filepath)
              ).sub(/\.[^\.\/\\]+$/,'')
              @filtergroups[id].dansguardian_id = dansguardian_id
            elsif File.file? filepath
              @filtergroups[id] = FilterGroup.new(
                :conffile         => filepath,
                :id               => nil,
                :dansguardian_id  => dansguardian_id
              )
            end
          end
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
