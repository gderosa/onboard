class OnBoard
  module System
    class Process

      class << self
        def running?(pid)
          # http://stackoverflow.com/a/325097
          begin
            return !!::Process.getpgid(pid)
          rescue Errno::ESRCH
            return false
          end
        end
        #
        # method_missing ?
        #
        # Do not break compat with code that believes they are calling Ruby core
        # instead of OnBoard::System::Process .
        def uid
          ::Process.uid
        end
        def gid
          ::Process.gid
        end
      end

      attr_reader :pid, :cwd, :exe, :cmdline, :env
      def initialize(pid)
        @pid      = pid
        @cwd      = `sudo readlink /proc/#{@pid}/cwd`.strip
        @exe      = `sudo readlink /proc/#{@pid}/exe`.strip
        @cmdline_raw \
                  = File.read("/proc/#{@pid}/cmdline") if File.exists? "/proc/#{@pid}/cmdline"
        @cmdline  = @cmdline_raw.split("\0") if @cmdline_raw
        @env      = getenv()
      end
      def data
        {
          'pid'     => @pid,
          'cwd'     => @cwd,
          'exe'     => @exe,
          'cmdline' => @cmdline,
          'env'     => @env
        }
      end
      def kill(opt_h)
        # TODO: manage non-kilable processes by switching to kill -9
        # TODO: timeout
        opt_ary = []
        opt_ary << :sudo if opt_h[:sudo]
        msg = System::Command.run "kill #{@pid}", *opt_ary
        if opt_h[:wait]
          #while
          #    File.exists? "/proc/#{@pid}" or
          #    `pidof #{@cmdline[0]}`.split.include? @pid.to_s
          #    # be sure that pidof #{command_name} output is up-to-date
          #  pp @cmdline
          #  pp `pidof #{@cmdline[0]}`.split
          #  pp @pid
          #  sleep 0.1
          #end

          loop do
            sleep 0.1
            redo if File.exists? "/proc/#{@pid}"
            redo if @cmdline and `pidof #{@cmdline[0]}`.split.include?(@pid.to_s)
            break
          end
          sleep 0.1
        end
        return msg
      end
      def getenv
        env = {}
        ary = `sudo cat /proc/#{@pid}/environ`.split("\0")
        ary.each do |name_val|
          name_val.strip!
          if name_val =~ /^([^=]*)=([^=]*)$/
            env[$1] = $2
          end
        end
        return env
      end
    end
  end
end
