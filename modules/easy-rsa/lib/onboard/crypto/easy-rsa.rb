class OnBoard
  module Crypto
    module EasyRSA
      def self.create_dh(n)
        (1..10).each do |i|
          puts i
          sleep 2
        end
        File.open(
            OnBoard::ROOTDIR + 
            '/etc/config/crypto/ssl/dh' + n.to_s + '.pem',                 
        'w') do |f|
          f.puts n
        end
      end
    end
  end
end

