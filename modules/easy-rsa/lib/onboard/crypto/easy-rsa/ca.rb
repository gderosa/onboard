autoload :FileUtils, 'fileutils'
autoload :Filepath, 'filepath'

require 'onboard/crypto/easy-rsa'


class OnBoard
  module Crypto
    module EasyRSA

      module CA

        def self.HTTP_POST_data_invalid?(params)
          return "Invalid key size."        unless params['key_size'] =~ /^\d+$/
          return "Invalid expiry."          unless params['days']     =~ /^\d+$/
          return "Invalid country name."    unless params['C']        =~ 
              /^[A-Z][A-Z]$/i
          return "Invalid province/state."  unless params['ST']       =~ /\S/
          return "Invalid city name"        unless params['L']        =~ /\S/
          return "Invalid Organization name" \
                                            unless params['O']        =~ /\S/
          return "Invalid email address"    unless (
              params['emailAddress'] =~ /^[\w_\-\.]+@[\w_\-\.]+[^_\-]$/i )
          return false
        end

        def self.create_from_HTTP_request(params)
          if Dir.exists? KEYDIR
            msg = System::Command.run <<EOF
cd #{SCRIPTDIR}
export KEY_DIR=#{KEYDIR}
./clean-all
EOF
            return msg unless msg[:ok]
          end
          msg = System::Command.run <<EOF 
cd #{SCRIPTDIR}
. ./vars
export CACERT=#{SSL::CACERT}
export CAKEY=#{SSL::CAKEY}
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
              FileUtils.chown nil, 'onboard', SSL::CAKEY
              FileUtils.chmod 0640, SSL::CAKEY
            rescue
              FileUtils.chmod 0600, SSL::CAKEY
            end
          end
          return msg
        end

      end

    end
  end
end

