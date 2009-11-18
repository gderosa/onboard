require 'fileutils'

class OnBoard
  module Crypto
    module EasyRSA
      SCRIPTDIR = OnBoard::ROOTDIR + '/modules/easy-rsa/easy-rsa/2.0'

      def self.create_dh(n)
        System::Command.run <<EOF
cd #{SCRIPTDIR}
. ./vars
export KEY_SIZE=#{n} 
./build-dh
EOF
        FileUtils.cp( SCRIPTDIR + '/keys/dh' + n.to_s + '.pem', 
            OnBoard::ROOTDIR + '/etc/config/crypto/ssl/') 
      end

      module CA
=begin        
        HTTP_POST_PARAMS = {
          'key_size'  => /^\d+$/,
          'days'      => /^\d+$/,
          'C'         => /^[A-Z][A-Z]$/i,
          'L'         => 
        }

        def self.filter_HTTP_POST(params)
        end
=end
        def self.HTTP_POST_data_invalid?(params)
          return "Invalid key size."        unless params['key_size'] =~ /^\d+$/
          return "Invalid expiry."          unless params['days']     =~ /^\d+$/
          return "Invalid country name."    unless params['C']        =~ 
              /^[A-Z][A-Z]$/i
          return "Invalid province/state."  unless params['ST']       =~ /\S/
          return "Invalid city name"        unless params['L']        =~ /\S/
          return "Invalid Organization name" \
                                            unless params['O']        =~ /\S/
          #return "Invalid email address"    unless 
                                              params['emailAddress']  =~ 
                                                /^[\w_\-\.]+@[\w_\-\.]+[^_\-]$/i
          return false
        end

        def self.create_from_HTTP_request(params)
          msg = System::Command.run <<EOF 
cd #{SCRIPTDIR}
. ./vars
export KEY_SIZE=#{params['key_size']}
export CA_EXPIRE=#{params['days']}
export KEY_COUNTRY="#{params['C']}"
export KEY_PROVINCE="#{params['ST']}"
export KEY_CITY="#{params['L']}"
export KEY_ORG="#{params['O']}"
export KEY_OU="#{params['OU']}"
export KEY_EMAIL="#{params['emailAddress']}"
./pkitool --initca
EOF
          if msg[:ok]
            begin
              FileUtils.cp( SCRIPTDIR + '/keys/ca.crt', 
                  OnBoard::ROOTDIR + '/etc/config/crypto/ssl/')  
            rescue
              msg[:ok] = false
              msg[:err] = $!
            end
          end
          return msg
        end

      end

    end
  end
end

