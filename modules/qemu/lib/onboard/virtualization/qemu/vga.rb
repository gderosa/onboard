
class OnBoard
  module Virtualization
    module QEMU
      module VGA
        # Taken from QEMU man page
        OPTIONS = %w{cirrus std vmware qxl tcx cg3 virtio none}
      end
    end
  end
end
