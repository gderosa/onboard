require 'fileutils'

class OnBoard
  module Crypto
    module EasyRSA

      autoload :CA,   'onboard/crypto/easy-rsa/ca'
      autoload :Cert, 'onboard/crypto/easy-rsa/cert'

      SCRIPTDIR = OnBoard::ROOTDIR + '/modules/easy-rsa/easy-rsa/2.0'
      KEYDIR = OnBoard::RWDIR + '/var/lib/crypto/easy-rsa/keys'
      CRL = KEYDIR + '/crl.pem'

      def self.create_dh(n)
        FileUtils.mkdir_p KEYDIR unless Dir.exists? KEYDIR
        System::Command.run <<EOF
cd #{SCRIPTDIR}
export KEY_DIR=#{KEYDIR}
. ./vars
export KEY_SIZE=#{n} 
./build-dh
EOF
        FileUtils.mkdir_p SSL::DIR unless Dir.exists? SSL::DIR
        FileUtils.cp(KEYDIR + '/dh' + n.to_s + '.pem', SSL::DIR)  
      end

    end
  end
end

