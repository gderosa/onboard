require 'fileutils'

class OnBoard
  module Crypto
    module EasyRSA
      SCRIPTDIR = OnBoard::ROOTDIR + '/modules/easy-rsa/easy-rsa/2.0'

      def self.create_dh(n)
        puts "create_dh(#{n})"
        System::Command.run <<END
cd #{SCRIPTDIR}
. ./vars
KEY_SIZE=#{n} 
./build-dh
END
        FileUtils.cp( SCRIPTDIR + '/keys/dh' + n.to_s + '.pem', 
            OnBoard::ROOTDIR + '/etc/config/crypto/ssl/') 
      end

    end
  end
end

