class OnBoard

  module System
    autoload :Process, 'onboard/system/process'
  end

  module Network
    module AccessControl
      class Chilli
        DEFAULT_CONF_FILE = '/etc/chilli.conf'

        def self.getAll
          ary = []
          `pidof chilli`.split.each do |pid|
            ary << new(
              :process => OnBoard::System::Process.new(pid)
            )
          end
          return ary
        end

        def self.parse_conffile(filename)
          h = {}
          File.foreach(filename) do |line|
            line.sub! /#.*$/, ''
            if line =~ /(\S+)\s+(.*)\s*$/  
              opt, arg = $1, $2
              arg.strip!
              if arg =~ /^"(.*)"$/ # remove double quote
                arg = $1
              end
              if arg == "" # NOTE: necessary ?
                arg = true
              end
            elsif line =~ /(\S+)\s*$/
              opt, arg = $1, true
            else
              next
            end
            h[opt] = arg unless opt =~ /secret/ # do no export passwords
          end
          return h
        end

        attr_reader :data        
        
        def initialize(h)
          @process = h[:process]
          @conffile = conffile()
          @managed = managed()
          @conf = self.class.parse_conffile(@conffile)
        end

        # true if the config file is a subdirectory of 
        # OnBoard::Network::AccessControl::Chilli::CONFDIR
        def managed
          return true if @conffile[CONFDIR] 
          return false
        end

        def conffile
          # cache...
          if instance_variable_defined? :@conffile and @conffile
            return @conffile
          end
          cmdline = @process.cmdline # Array, like in ARGV ...
          index = cmdline.index('--conf') 
          unless index # --conf option not found
            @conffile = DEFAULT_CONF_FILE
            return @conffile 
          end
          argument = cmdline[index + 1] 
          if argument =~ /^\-/
            fail "bad chilli command line: #{cmdline.inspect}" 
          end
          if argument =~ /^\// # absolute path
            @conffile = argument
          else
            @conffile = File.join @process.cwd, argument
          end
          return @conffile
        end

        def data
          {
            'process'   => {
              'pid'       => @process.pid,
              'cmdline'   => @process.cmdline,
              'cwd'       => @process.cwd
            },
            'conffile'  => conffile(),
            'conf'      => @conf
          }
        end

      end
    end
  end
end

