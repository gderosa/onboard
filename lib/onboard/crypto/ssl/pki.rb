require 'erb'
require 'openssl'
require 'facets/hash'

require 'onboard/extensions/openssl'
require 'onboard/crypto/ssl'
require 'onboard/crypto/ssl/multi'

class OnBoard
  module Crypto
    module SSL
      class PKI
        SLASH_FILENAME_ESCAPE = '__slash__'
        SYSTEM_PKIS = %w{default}

        class ArgumentError < ::ArgumentError; end
        class Conflict < ::RuntimeError; end

        def self.get_all
          Multi.get_pki_names.map{|pkiname| self.new(pkiname)}
        end

        def self.guess_pkiname(h)
          if h[:filepath] =~ %r{#{Multi::SUBDIR}/([^/]+)/}
            return $1
          elsif h[:filepath] =~ %r{^(.*/)?ssl/cert/.}
            return 'default'
          end
        end

        attr_reader :name, :ca, :cadata

        def initialize(name)
          @name = name =~ /\S/ ? name : 'default'
          @ca = nil
          @cadata = {}
        end

        def datadir
          File.join(
            OnBoard::Crypto::SSL::DATADIR,
            OnBoard::Crypto::SSL::Multi::SUBDIR,
            @name
          )
        end
        def certdir
          File.join datadir, 'cert'
        end
        def keydir
          File.join certdir, 'private'
        end
        def cacertpath
          File.join datadir, 'ca/ca.crt'
        end
        def cakeypath
          File.join datadir, 'ca/private/ca.key'
        end
        def exists?
          Dir.exists? datadir
        end

        def system?
          SYSTEM_PKIS.include? @name
        end

        def delete!
          FileUtils.rm_r(datadir, :secure => true) unless system?
        end

        def get_cadata!
          begin
            @ca = OpenSSL::X509::Certificate.new(File.read cacertpath)
            @cadata = {'cert' => @ca.to_h}
          rescue Errno::ENOENT
          rescue OpenSSL::X509::CertificateError
            @cadata = {'err' => $!}
          end
          return @cadata
        end

        def has_certs?
          num_certs > 0
        end
        def num_certs
          Dir.glob("#{certdir}/*.crt").size
        end

        def getAllCerts(opt_h={})
          opt_h_default = {
            :certs  => {
              :dir    => certdir,
              :ext    => 'crt'
            },
            :keys   => {
              :dir    => keydir,
              :ext    => 'key'
            },
            :crls   => {
              :ext    => 'crl'
            }
          }
          opt_h = opt_h_default.deep_merge opt_h
          opt_h[:crls][:dir] ||= opt_h[:certs][:dir]

          h = {} # return value

          get_cadata!

          if opt_h[:with_ca]
            if @cadata['cert']
              h['__pki_ca_cert__'] = @cadata
            end
          end

          # sugar
          certdir = opt_h[:certs][:dir]
          certext = opt_h[:certs][:ext]
          keydir  = opt_h[:keys][:dir]
          keyext  = opt_h[:keys][:ext]
          crldir  = opt_h[:crls][:dir]
          crlext  = opt_h[:crls][:ext]

          Dir.glob "#{certdir}/*.#{certext}" do |certfile|
            name = File.basename(certfile).sub(/\.#{certext}$/, '')
            h[name] = {'cert' => {}}
            keyfile = "#{keydir}/#{name}.#{keyext}"
            begin
              certobj = OpenSSL::X509::Certificate.new(File.read certfile)
              signed_by_our_CA = false
              signed_by_our_CA = certobj.verify(@ca.public_key) if @ca.respond_to? :public_key
              h[name] = {
                  'cert'              => certobj.to_h,
                  'private_key'       => false,
                  'signed_by_our_CA'  => signed_by_our_CA
              }
            rescue OpenSSL::X509::CertificateError
              h[name] = {'cert' => {'err' => $!}}
            end

            # CRL feature has been buggy since single-PKI version...
            # # CRL:
            # # very simple match by filename, no OpenSSL check
            # # (was made at file upload... somewhat :-P)
            # if File.readable? "#{crldir}/#{name}.#{crlext}"
            #   h[name]['crl'] = "#{name}.#{crlext}"
            # end

            if File.exists? keyfile
              begin
                if certobj.check_private_key(
                    OpenSSL::PKey::RSA.new(File.read keyfile)
                )
                  h[name]['private_key'] = {'ok' => true}
                else
                  h[name]['private_key'] = {
                    'ok'  => false,
                    'err' => 'Private key verification failed'
                  }
                end
              rescue
                h[name]['private_key'] = {
                  'ok'  => false,
                  'err' => $!
                }
              end
            end
          end
          return h
        end



        def dh(n_or_file)
          dh_ = nil
          begin
            if n_or_file.kind_of? Numeric or n_or_file.to_i > 0
              dh_ = OpenSSL::PKey::DH.new(
                  File.read(datadir + '/dh' + n_or_file.to_s + '.pem')
              )
            else
              dh_ = OpenSSL::PKey::DH.new(File.read(n_or_file))
            end
          rescue
            return false
          end

          if n_or_file.kind_of? Numeric or n_or_file.to_i > 0
            if dh_.params['p'].to_i.to_s(2).length != n_or_file.to_i
              # TODO: a less convoluted way to check the bit length/size of
              #  Diffie Hellman params?
              return false
            end
          end

          return dh_
        end

        alias :dh_exists? :dh

      end
    end
  end
end

