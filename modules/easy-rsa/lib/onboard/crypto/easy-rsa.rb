require 'fileutils'

class OnBoard
  module Crypto
    module EasyRSA
      SCRIPTDIR = OnBoard::ROOTDIR + '/modules/easy-rsa/easy-rsa/2.0'

      def self.create_dh(n)
        System::Command.run <<EOF
cd #{SCRIPTDIR}
. ./vars
KEY_SIZE=#{n} 
./build-dh
EOF
        FileUtils.cp( SCRIPTDIR + '/keys/dh' + n.to_s + '.pem', 
            OnBoard::ROOTDIR + '/etc/config/crypto/ssl/') 
      end

      def self.create_from_HTTP_request(params)
        System::Command.run <<EOF 
cd #{SCRIPTDIR}
. ./vars
KEY_SIZE=#{params['key_size']}

./build-ca
EOF
      end

    end
  end
end

