require 'dansguardian'

require 'onboard/extensions/erb'
require 'onboard/content-filter/dg/constants'

autoload :YAML, 'yaml'

class OnBoard
  module ContentFilter
    class DG

      autoload :ManagedList,    'onboard/content-filter/dg/managed-list'
      autoload :FilterGroup,    'onboard/content-filter/dg/filter-group'
      autoload :AuthPlugin,     'onboard/content-filter/dg/auth-plugin'
      autoload :ContentScanner, 'onboard/content-filter/dg/content-scanner'

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

        def saverestore_file
          "#{CONFDIR}/onboard.yaml"
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
        get_status
        return false if @pid[:parent] == 0
        return @pid[:parent]
      end

      def root;             self.class.root;              end
      def config_file;      self.class.config_file;       end
      def fg_file(fgid);    self.class.fg_file(fgid);     end
      def saverestore_file; self.class.saverestore_file;  end

      def write_all
        dg = self
        ERB::recurse CONFTEMPLATEDIR, binding, '.erb' do |subpath|
          "#{CONFDIR}/#{subpath}"
        end
      end

      def get_status
        output = `sudo dansguardian -c #{config_file} -s 2>&1`
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

      # For example:
      #   dansguardianf1.conf # real file
      #   dansguardianf2.conf # real file
      #   dansguardianf3.conf # symlink to dansguardianf1.conf ("deleted")
      #   dansguardianf4.conf # real file
      #   dansguardianf5.conf # symlink to dansguardianf1.conf ("deleted")
      #   dansguardianf6.conf # symlink to dansguardianf1.conf ("deleted")
      #
      # In this case, dansguardianf5.conf and dansguardianf6.conf
      # will be deleted and "filtergroups = 4" will be set in dansguardian.conf
      def fix_filtergroups
        fg_statuses     = []
        to_be_unlinked  = []
        filtergroups    = 1
        Dir.glob "#{CONFDIR}/dansguardianf*.conf" do |filepath|
          if filepath =~ /dansguardianf(\d+)\.conf$/
            fgid = $1.to_i
            if File.symlink? filepath and (
              File.readlink(filepath) == "#{CONFDIR}/dansguardianf1.conf" or
              File.readlink(filepath) == 'dansguardianf1.conf'
            )
              fg_statuses[ fgid - 1 ] = :deleted
            else
              fg_statuses[ fgid - 1 ] = :active
            end
          end
          fg_statuses.each_with_index do |fg_status, i|
            if fg_status == :active
              to_be_unlinked  = []
              filtergroups = i + 1
            elsif fg_status == :deleted
              to_be_unlinked << i + 1
            end
          end
        end
        ::DansGuardian::Updater.update!(
          "#{CONFDIR}/dansguardian.conf",
          :filtergroups => filtergroups
        )
        to_be_unlinked.each do |fgid|
          FileUtils.rm "#{CONFDIR}/dansguardianf#{fgid}.conf"
        end
      end

      def edit_main_config!(params)
        u = {}

        %w{weightedphrasemode preservecase maxuploadsize}.each do |name|
          u[name] = params[name]
        end

        u['authplugin'] = []
        if params['authplugin'].respond_to? :each_pair
          params['authplugin'].each_pair do |k, v|
            u['authplugin'] << AuthPlugin.config_file(k) if v == 'on'
          end
        end

        u['contentscanner'] = []
        if params['contentscanner'].respond_to? :each_pair
          params['contentscanner'].each_pair do |k, v|
            u['contentscanner'] << ContentScanner.config_file(k) if v == 'on'
          end
        end

        ::DansGuardian::Updater.update! config_file, u
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
        System::Command.run "dansguardian -c #{config_file} -q", :sudo
      end

      def restart
        System::Command.run "dansguardian -c #{config_file} -Q", :sudo
      end

      def reload
        System::Command.run "dansguardian -c #{config_file} -r", :sudo
      end

      def reload_groups
        # This is buggy:
        # System::Command.run "dansguardian -c #{config_file} -g", :sudo

        # use HUP instead of USR1: it's safer and not that slower
        reload
      end

      def to_h
        h = {
          'config'                => {
            'main'                  => @config.main.data
          },
          'deleted_filtergroups'  => @deleted_filtergroups,
          'pid'                   => @pid
        }
        h['config']['filtergroups'] = {}
        1.upto @config.main[:filtergroups] do |fgid|
          unless @deleted_filtergroups.include? fgid
            h['config']['filtergroups'][fgid.to_i] = @config.filtergroup(fgid).data
          end
        end
        return h
      end
      alias export to_h

      def to_json(*args); export.to_json(*args); end
      def to_yaml(*args); export.to_yaml(*args); end

      def save
        begin
          File.open saverestore_file, 'w' do |f|
            f.write YAML.dump (
              {
                :running => running?
              }
            )
          end
        rescue Errno::ENOENT
          write_all
          retry
        end
      end

      def restore
        begin
          saved_data = YAML.load File.read saverestore_file
          start if saved_data[:running] and not running?
        rescue Errno::ENOENT
        end
      end

    end
  end
end
