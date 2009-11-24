require 'onboard/crypto/easy-rsa'
require 'fileutils'

class OnBoard
  module Crypto
    module EasyRSA
      module Cert

        def self.HTTP_POST_data_invalid?(params)
          return "Invalid key size."        unless params['key_size'] =~ /^\d+$/
          return "Invalid expiry."          unless params['days']     =~ /^\d+$/
          return "Invalid country name."    unless params['C']        =~ 
              /^[A-Z][A-Z]$/i
          return "Invalid province/state."  unless params['ST']       =~ /\S/
          return "Invalid city name"        unless params['L']        =~ /\S/
          return "Invalid Organization name" \
                                            unless params['O']        =~ /\S/
          return "Invalid Common Name"      unless params['CN']       =~ /\S/ 
          return "Invalid email address"    unless (
              params['emailAddress'] =~ /^[\w_\-\.]+@[\w_\-\.]+[^_\-]$/i )
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
./pkitool #{'--server' if params['type'] == 'server'} "#{params['CN']}" 
EOF
          destkey = SSL::CERTDIR + "/private/#{params['CN']}.key"
          if msg[:ok] 
            begin
              # hard links
              FileUtils.ln(
                  SCRIPTDIR + "/keys/#{params['CN']}.crt", 
                  SSL::CERTDIR 
              )
              FileUtils.ln( 
                  SCRIPTDIR + "/keys/#{params['CN']}.key", 
                  destkey  
              ) 
            rescue
              msg[:ok] = false
              msg[:err] = $!
            end
            begin
              FileUtils.chown nil, 'onboard', destkey
              FileUtils.chmod 0640, destkey
            rescue
              FileUtils.chmod 0600, destkey
            end
          end
          return msg
        end

      end
    end
  end
end

