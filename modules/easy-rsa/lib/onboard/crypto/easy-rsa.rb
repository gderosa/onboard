require 'fileutils'

class OnBoard
  module Crypto
    module EasyRSA

      autoload :CA,   'onboard/crypto/easy-rsa/ca'
      autoload :Cert, 'onboard/crypto/easy-rsa/cert'

      SCRIPTDIR = OnBoard::ROOTDIR + '/modules/easy-rsa/easy-rsa/2.0'
      KEYDIR = OnBoard::CONFDIR + '/var/lib/crypto/easy-rsa/keys'
      CRL = KEYDIR + '/crl.pem'

      def self.create_dh(n)
        System::Command.run <<EOF
cd #{SCRIPTDIR}
. ./vars
export KEY_SIZE=#{n} 
./build-dh
EOF
        FileUtils.mkdir_p SSL::DIR unless Dir.exists? SSL::DIR
        FileUtils.cp(SCRIPTDIR + '/keys/dh' + n.to_s + '.pem', SSL::DIR)  
      end

    end
  end
end

