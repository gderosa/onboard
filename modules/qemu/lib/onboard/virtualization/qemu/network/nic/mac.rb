class OnBoard
  module Virtualization
    module QEMU
      module Network
        class NIC
          class MAC < ::OnBoard::Network::Interface::MAC

            class << self

              #  Lots of ducumentation refer to DE:AD:BE:??:??:?? which should
              #  be outside any real NIC vendor space...
              def random
                new(0xDEADBE000000 + rand(0x1000000)) 
              end

            end

          end
        end
      end
    end
  end
end
