require 'fileutils'
require 'pathname'

require 'onboard/crypto/easy-rsa'

class OnBoard
  module Crypto
    module EasyRSA
      module Cert

        def self.HTTP_POST_data_invalid?(params)
          return "Invalid key size."        unless params['key_size'] =~ /^\d+$/
          return "Invalid expiry."          unless params['days']     =~ /^\d+$/
          return "Invalid Country code."    unless params['C']        =~ 
              /^[A-Z][A-Z]$/i
          return "Missing province/state."  unless params['ST']       =~ /\S/
          return "Missing city name"        unless params['L']        =~ /\S/
          return "Missing Organization Name" \
                                            unless params['O']        =~ /\S/
          return "Missing Common Name"      unless params['CN']       =~ /\S/ 
          return "Invalid email address"    unless (
              params['emailAddress'] =~ /^[\w_\-\.]+@[\w_\-\.]+[^_\-]$/i )
          return false
        end

        def self.create_from_HTTP_request(params)

          # First, create necessary files if they are missing
          File.mkdir SCRIPTDIR + '/keys' unless Dir.exists?(SCRIPTDIR + '/keys')
          %w{index.txt serial}.each do |file|
            path = SCRIPTDIR + '/keys/' + file
            unless File.exists? path
              File.new(path, 'w') 
            end
          end
          serfile = SCRIPTDIR + '/keys/serial'
          unless File.read(serfile).strip =~ /^([a-f\d][a-f\d])+$/i
            File.open serfile, 'w' do |f|
              f.puts '01'
            end
          end

          if Crypto::SSL.getAllCerts.values.detect do |c|
            c['cert']['subject']['CN'] == params['CN']
          end
            msg = {
              :ok => false,
              :err_html => "A certificate with the same Common Name &ldquo;<code>#{params['CN']}</code>&rdquo; already exists!",
              :err => 'A certificate with the same Common Name already exists!'
            }
          else
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
./pkitool #{'--server' if params['type'] == 'server'} "#{params['CN']}" 
EOF
            if msg[:ok] 
              destcert = "#{SSL::CERTDIR}/#{params['CN']}.crt"
              destkey = "#{SSL::KEYDIR}/#{params['CN']}.key"
              certpn = Pathname.new destcert
              keypn  = Pathname.new destkey
              easy_rsa_keydir_pn = Pathname.new EasyRSA::KEYDIR
              begin
                FileUtils.mv(
                    SCRIPTDIR + "/keys/#{params['CN']}.crt", 
                    SSL::CERTDIR 
                )
                FileUtils.symlink(
                    certpn.relative_path_from(easy_rsa_keydir_pn),
                    EasyRSA::KEYDIR
                )              
                FileUtils.mv( 
                    SCRIPTDIR + "/keys/#{params['CN']}.key", 
                    SSL::KEYDIR  
                )
                FileUtils.symlink(
                    keypn.relative_path_from(easy_rsa_keydir_pn),
                    EasyRSA::KEYDIR
                )              
                begin
                  FileUtils.chown nil, 'onboard', destkey
                  FileUtils.chmod 0640, destkey
                rescue
                  FileUtils.chmod 0600, destkey
                end
              rescue
                msg[:ok] = false
                msg[:err] = $!
              end
            end
          end
          return msg
        end

      end
    end
  end
end

