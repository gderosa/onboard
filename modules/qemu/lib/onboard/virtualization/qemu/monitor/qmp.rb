require 'socket'
require 'json'

class OnBoard
  module Virtualization
    module QEMU
      class Monitor
        class QMP < Monitor

          def execute(command, arguments={})
            retry_time    = 0.0
            timeout       = 1.0
            pause         = 0.2
            begin
              UNIXSocket.open(unix_path) do |uds| # TODO: timeouts
                greeting = uds.gets
                uds.puts '{ "execute": "qmp_capabilities" }'
                capabilities = uds.gets
                uds.puts JSON.dump( {
                  'execute' => command,
                  'arguments' => arguments
                } )
                return uds.gets
              end
            rescue Errno::ECONNRESET, Errno::ECONNREFUSED
              retry_time += pause
              if retry_time < timeout
                sleep pause
                retry
              else
                LOGGER.error $!
                return JSON.dump({'error' => {'message' => $!}})
              end
            end
          end

        end
      end
    end
  end
end
