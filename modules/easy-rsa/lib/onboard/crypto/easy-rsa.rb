require 'fileutils'
require 'onboard/crypto/ssl'
require 'onboard/crypto/ssl/multi'
require 'onboard/crypto/easy-rsa/ca'
require 'onboard/crypto/easy-rsa/cert'

class OnBoard
  module Crypto
    module EasyRSA

      SCRIPTDIR = OnBoard::ROOTDIR + '/modules/easy-rsa/easy-rsa/2.0'
      DATADIR = OnBoard::RWDIR + '/var/lib/crypto/easy-rsa'

      module Multi

        SUBDIR = SSL::Multi::SUBDIR
        DATADIR = File.join EasyRSA::DATADIR, SUBDIR
        DEFAULTPKIDIR = File.join DATADIR, 'default'

        class << self
          def handle_legacy
            SSL::Multi.handle_legacy
            unless File.exists? DATADIR
              FileUtils.mkdir_p DATADIR
            end
            unless File.exists? DEFAULTPKIDIR
              FileUtils.ln_s '..', DEFAULTPKIDIR
            end
          end
          def add_pki(pkiname)
            mkdir(pkiname)
          end
          def mkdir(pkiname)
            FileUtils.mkdir_p File.join SSL::DATADIR, Multi::SUBDIR, pkiname
            FileUtils.mkdir_p File.join EasyRSA::DATADIR, Multi::SUBDIR, pkiname
          end
        end

      end

      class PKI
        SYSTEM_PKIS = %w{default}

        @@dh_mutexes = {} unless class_variable_defined? :@@dh_mutexes

        def initialize(name)
          @name = name
          @sslpki = SSL::PKI.new(name)
          @@dh_mutexes[@name] ||= {}
        end

        # Mutual exclusion for threads creating Diffie-Hellman parameters
        def dh_mutex(n)
          @@dh_mutexes[@name][n] = Mutex.new unless @@dh_mutexes[@name][n]
          return @@dh_mutexes[@name][n]
        end

        def datadir
          File.join DATADIR, Multi::SUBDIR, @name
        end
        def keydir
          File.join datadir, 'keys'
        end

        def exists?
          Dir.exists? datadir
        end

        def delete!
          FileUtils.rm_r(datadir, :secure => true) unless SYSTEM_PKIS.include? @name
        end

        def create_dh(n, opts={})
          opts_default = {:dsaparam_above => 2048}
          opts = opts_default.merge(opts)
          FileUtils.mkdir_p keydir unless Dir.exists? keydir
          build_dh = 'build-dh'
          if n.respond_to? :to_i and n.to_i > opts[:dsaparam_above]
            build_dh = 'build-dh.dsaparam'  # faster
          end
          System::Command.run <<EOF
cd #{SCRIPTDIR}
export KEY_DIR=#{keydir}
. ./vars
export KEY_SIZE=#{n}
./#{build_dh}
EOF
          FileUtils.mkdir_p @sslpki.datadir unless Dir.exists? @sslpki.datadir
          dhfile_orig = keydir + '/dh' + n.to_s + '.pem'
          if File.exists? dhfile_orig
            # Not sure why the above "if" is needed:
            # is another thread creating the dh file?
            # then mutex does not work?
            # The answer probably lies in the fact that the controller checks existence in etc/crypto/ssl
            # instead of var/lib/crypto/easy-rsa (TODO: fix that);
            # so an extra thread may be queued
            FileUtils.cp(dhfile_orig, @sslpki.datadir)
            LOGGER.info "#{self.class}: generated #{dhfile_orig} and copied into #{@sslpki.datadir}/ ."
          else
            LOGGER.warn "#{self.class}: A thread supposed to create #{dhfile_orig} did not find it; this may be harmless if another thread sorts it."
          end
        end

        def getAllDH
          dh_h = {}
          n = nil
          SSL::KEY_SIZES.each do |n|
            dh_file = "dh#{n}.pem"
            dh_file_fullpath = File.join(@sslpki.datadir, dh_file)
            dh_h[dh_file] = {} unless dh_h[dh_file]
            if @@dh_mutexes[@name][n] and @@dh_mutexes[@name][n].respond_to? :locked?
              dh_h[dh_file]['being_created'] = @@dh_mutexes[@name][n].locked?
            else
              dh_h[dh_file]['being_created'] = false
            end
            begin
              dh_h[dh_file]['size'] =
                  @sslpki.dh(dh_file_fullpath).params['p'].to_i.to_s(2).length
            rescue NoMethodError
              dh_h[dh_file]['err'] = 'no valid data: ' + $!.message
            end
          end
          return dh_h
        end

        def getAll
          h = {}
          h['dh'] = getAllDH()
          begin
            @our_CA = OpenSSL::X509::Certificate.new(File.read @sslpki.cacertpath)
            h['ca'] = @our_CA.to_h
          rescue Errno::ENOENT
          rescue OpenSSL::X509::CertificateError
            h['ca'] = {'err' => $!}
          end
          h['certs'] = @sslpki.getAllCerts()
          return h
        end
      end
    end
  end
end

