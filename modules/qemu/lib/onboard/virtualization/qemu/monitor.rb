require 'socket'
require 'timeout'

class OnBoard
  module Virtualization
    module QEMU
      class Monitor

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
                banner = uds.gets         # unused, just to go ahead
                prompt = uds.gets         # tipically "(qemu) \r\n"

                uds.puts msg
                spurious_line = uds.gets  # lots of terminal escape sequences, go ahead

                line = ''

                # Last line has no trailing line-terminating char, so we have to
                # perform some character-level operations.

                while (line != prompt.sub(/\r?\n/, '') ) 
                    # "(qemu) " or something
                  c = uds.getc
                  line << c
                  if c == "\n"
                    out << line
                    line = ''
                  end
                end

              end # UNIXSocket
            end # Timeout
          rescue Timeout::Error
            out << '[Monitor Error: Socket Timed Out]'
          end
          return out
        end

      end
    end
  end
end
