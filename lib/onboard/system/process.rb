class OnBoard
  module System
    class Process
      attr_reader :pid, :cwd, :exe, :cmdline
      def initialize(pid)
        @pid      = pid
        @cwd      = `sudo readlink /proc/#{@pid}/cwd`.strip
        @exe      = `sudo readlink /proc/#{@pid}/exe`.strip
        @cmdline  = File.read("/proc/#{@pid}/cmdline").split("\0")
      end
      def env
        @env = {}
        ary = `sudo cat /proc/#{@pid}/environ`.split("\0")
        ary.each do |name_val|
          name_val.strip!
          if name_val =~ /^([^=]*)=([^=]*)$/ 
            @env[$1] = $2
          end
        end
        return @env
      end
    end  
  end
end
