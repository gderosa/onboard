class OnBoard
  module System
    class Process
      attr_reader :pid, :cwd, :exe, :cmdline, :env
      def initialize(pid)
        @pid      = pid
        @cwd      = `sudo readlink /proc/#{@pid}/cwd`.strip
        @exe      = `sudo readlink /proc/#{@pid}/exe`.strip
        @cmdline_raw \
                  = File.read("/proc/#{@pid}/cmdline")
        @cmdline  = @cmdline_raw.split("\0")
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
        opt_ary = []
        opt_ary << :sudo if opt_h[:sudo]
        msg = System::Command.run "kill #{@pid}", *opt_ary
        if opt_h[:wait]
          sleep 0.1 while File.exists? "/proc/#{@pid}"
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
