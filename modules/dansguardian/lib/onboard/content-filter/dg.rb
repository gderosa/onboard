require 'dansguardian'

require 'onboard/extensions/erb'
require 'onboard/content-filter/dg/constants'

class OnBoard
  module ContentFilter
    class DG

      class << self

        def root
          CONFDIR
        end

        def config_file
          "#{CONFDIR}/dansguardian.conf"
        end

        def fg_file(fgid)
          "#{CONFDIR}/dansguardianf#{fgid}.conf"  
        end

      end

      attr_reader :pid, :config, :deleted_filtergroups

      def initialize(opts={:bare => false}) 
        reset
        get_info unless opts[:bare] 
      end

      def reset
        reset_pid
        @config         = nil
      end

      def reset_pid
        @pid            = {
          :parent         => nil,
          :children       => []
        }
      end

      def get_info
        @config         = ::DansGuardian::Config.new(:mainfile => config_file)
        get_deleted_filtergroups
        get_status
      end
      alias update_info get_info

      def running?
        return false if @pid[:parent] == 0
        return @pid[:parent]
      end

      def root;           self.class.root;          end
      def config_file;    self.class.config_file;   end
      def fg_file(fgid);  self.class.fg_file(fgid); end

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
          reset_pid
        end
        @dansguardian_s_string = output
      end

      # Mark as deleted a filtergroup whose config file is just a symlink
      # to dansguardianf1.conf
      def get_deleted_filtergroups
        @deleted_filtergroups = []
        Dir.glob "#{CONFDIR}/dansguardianf*.conf" do |filepath|
          if filepath =~ /dansguardianf(\d+)\.conf$/
            fgid = $1.to_i
            if File.symlink? filepath
              if 
                  File.readlink(filepath) == "#{CONFDIR}/dansguardianf1.conf" or
                  File.readlink(filepath) == 'dansguardianf1.conf'
                @deleted_filtergroups << fgid
              end
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

      def reload
        System::Command.run 'dansguardian -r', :sudo
      end

      def reload_groups
        System::Command.run 'dansguardian -g', :sudo
      end

    end
  end
end
