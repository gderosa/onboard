require 'fileutils'
require 'pathname'

require 'onboard/crypto/ssl'
require 'onboard/crypto/ssl/pki'
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
          ssl_pki = SSL::PKI.new params[:pkiname]
          easyrsa_pki = EasyRSA::PKI.new params[:pkiname]

          # First, create necessary files if they are missing
          [ssl_pki.certdir, ssl_pki.keydir, easyrsa_pki.keydir].each do |dir|
            FileUtils.mkdir_p dir unless Dir.exists? dir
          end
          %w{index.txt serial}.each do |file|
            path = File.join easyrsa_pki.keydir, file
            unless File.exists? path
              File.new(path, 'w')
            end
          end
          serfile = File.join easyrsa_pki.keydir, 'serial'
          unless File.read(serfile).strip =~ /^([a-f\d][a-f\d])+$/i
            File.open serfile, 'w' do |f|
              f.puts '01'
            end
          end

          if ssl_pki.getAllCerts.values.detect do |c|
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
export KEY_DIR=#{easyrsa_pki.keydir}
. ./vars
export CACERT=#{ssl_pki.cacertpath}
export CAKEY=#{ssl_pki.cakeypath}
export KEY_SIZE=#{params['key_size']}
export KEY_EXPIRE=#{params['days']}
export KEY_COUNTRY="#{params['C']}"
export KEY_PROVINCE="#{params['ST']}"
export KEY_CITY="#{params['L']}"
export KEY_ORG="#{params['O']}"
export KEY_OU="#{params['OU']}"
export KEY_EMAIL="#{params['emailAddress']}"
./pkitool #{'--server' if params['type'] == 'server'} "#{params['CN']}"
EOF
            if msg[:ok]
              destcert = "#{ssl_pki.certdir}/#{params['CN']}.crt"
              destkey = "#{ssl_pki.keydir}/#{params['CN']}.key"
              begin
                FileUtils.mv(
                    easyrsa_pki.keydir + "/#{params['CN']}.crt",
                    ssl_pki.certdir
                )
                FileUtils.symlink(
                    destcert,
                    easyrsa_pki.keydir
                )
                FileUtils.mv(
                    easyrsa_pki.keydir + "/#{params['CN']}.key",
                    ssl_pki.keydir
                )
                FileUtils.symlink(
                    destkey,
                    easyrsa_pki.keydir
                )
                begin
                  FileUtils.chown nil, Process.gid, destkey
                  FileUtils.chown nil, Process.gid, destcert
                  FileUtils.chmod 0640, destkey
                  FileUtils.chmod 0644, destcert
                rescue
                  FileUtils.chmod 0600, destkey
                  FileUtils.chmod 0644, destcert
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

