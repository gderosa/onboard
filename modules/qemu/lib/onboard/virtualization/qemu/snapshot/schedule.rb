class OnBoard
  module Virtualization
    module QEMU
      class Snapshot
        module Schedule
          class << self
            def manage(h)
              pp h[:http_params]['snapshot_schedule'] # DEBUG
              pp h[:http_params]['vmid']              # DEBUG
            end
          end
        end
      end
    end
  end
end

