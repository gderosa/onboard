require 'onboard/network/interface'

class OnBoard
  module Network
    module OpenVPN
      class Interface < ::OnBoard::Network::Interface
        module Name
          def self.generate
            n = 0
            names = Interface.getAll.map{|x| x.name}
            name_ = nil
            while names.include? (name_ = "ovpn#{n}")
              n += 1
            end
            return name_
          end
        end
      end
    end
  end
end
