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
# Disabled due to https://bugs.launchpad.net/qemu/+bug/1185888
# TODO: make it a user choice, with proper warning
=begin
            {
              'driver'    => 'nec-usb-xhci',
              'id'        => 'xhci',
              '_comment'  => 'USB 3.0'
            },
=end
          ]

          DEFAULT_DEVICES     = [
            {
              'driver'    => 'usb-tablet',
              'bus'       => DEFAULT_CONTROLLERS.first['id'] + '.0' 
            },
          ]

        end

      end
    end
  end
end


