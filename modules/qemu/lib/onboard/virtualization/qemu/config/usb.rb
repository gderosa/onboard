class OnBoard
  module Virtualization
    module QEMU
      class Config

        module USB
          DEFAULT_CONTROLLERS = [
            {
              'driver'    => 'piix3-usb-uhci',
              'id'        => 'piix3-uhci',
              '_comment'  => 'USB 1.1'
            },
            {
              'driver'    => 'usb-ehci',
              'id'        => 'ehci',
              '_comment'  => 'USB 2.0'
            },
            {
              'driver'    => 'nec-usb-xhci',
              'id'        => 'xhci',
              '_comment'  => 'USB 3.0'
            },
          ]
        end

      end
    end
  end
end


