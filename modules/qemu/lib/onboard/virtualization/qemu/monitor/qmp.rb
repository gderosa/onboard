require 'socket'
require 'json'

class OnBoard
  module Virtualization
    module QEMU
      class Monitor
        class QMP < Monitor

          def execute(command, arguments={})
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
          end

        end
      end
    end
  end
end
