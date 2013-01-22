class OnBoard
  module System
    module Shutdown
      class << self
        def halt
          Command.send_command 'shutdown -h now', :sudo
        end
        def reboot
          Command.send_command 'shutdown -r now', :sudo
        end
      end
    end
  end
end
