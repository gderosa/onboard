require 'socket'
require 'timeout'

require 'onboard/extensions/logger'

class OnBoard
  module Virtualization
    module QEMU

      class MonitorError < RuntimeError; end

      class Monitor


        # TODO: make this class "abstract", moving most of its logic to
        # a fresh Monitor::HMP class (human monitor, as opposed to QMP)
        # See also
        # http://git.qemu.org/?p=qemu.git;a=blob_plain;f=docs/qmp/README;hb=HEAD

        autoload :QMP, 'onboard/virtualization/qemu/monitor/qmp'

        def initialize(h)
          @config = h
        end

        def unix_path
          @config['unix']
        end

        def sendrecv(msg='', opts={}) # UNIXSocket only currently supported
         
          out = ''
          opts = {:timeout => 1}.merge(opts)  

          begin
            timeout(opts[:timeout]) do
              UNIXSocket.open(unix_path) do |uds|
                uds.puts                  # just to get the prompt
                banner = uds.gets         # unused, just to go ahead, could be empty
                prompt_long = uds.gets    # "(qemu)" or "(qemu) QEMU 1.5.0 ..."
                prompt_long =~ /^\s*(\S+)/
                prompt = $1

                uds.puts msg
                spurious_line = uds.gets  
                    # lots of terminal escape sequences, go ahead

                line = ''

                # Last line has no trailing line-terminating char, so we have to
                # perform some character-level operations.

                while (line.strip != prompt) 
                    # "(qemu)" or something
                  c = uds.getc
                  break unless c
                  line << c
                  if c == "\n"
                    out << line
                    line = ''
                  end
                end

              end # UNIXSocket
            end # Timeout
          rescue \
                  ::Timeout::Error, 
                  ::Errno::ECONNRESET, 
                  ::Errno::ECONNREFUSED, 
                  ::Errno::ENOENT
            LOGGER.handled_error $! 
            out << "[Monitor Error: #{$!}]" unless opts[:on_errors] == :silent
            if opts[:raise] == :monitor
              raise MonitorError, $!
            elsif opts[:raise]
              raise
            end
          end
          if opts[:log] == :verbose  
            LOGGER.debug "qemu: Monitor socket at #{unix_path}"
            LOGGER.debug "qemu: message to Monitor: #{msg}"
            LOGGER.debug "qemu: Monitor result: #{out}" 
          end
          return out
        end

      end
    end
  end
end
