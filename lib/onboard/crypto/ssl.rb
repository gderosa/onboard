require 'erb'
require 'openssl'
require 'onboard/extensions/openssl'

class OnBoard
  module Crypto
    module SSL
      DIR                   = OnBoard::ROOTDIR + '/etc/config/crypto/ssl'
      CERTDIR               = DIR + '/cert'
      KEYDIR                = CERTDIR + '/private'
      KEY_SIZES             = [1024, 2048]
      CACERT                = DIR + '/ca/ca.crt'
      CAKEY                 = DIR + '/ca/private/ca.key'
      SLASH_FILENAME_ESCAPE = '__slash__'

      @@dh_mutexes = {} unless class_variable_defined? :@@dh_mutexes
      @@our_CA = nil unless class_variable_defined? :@@our_CA

      class ArgumentError < ::ArgumentError; end
      class Conflict < ::RuntimeError; end

      class << self

        # Mutual exclusion for threads creating Diffie-Hellman parameters
        def dh_mutex(n)
          @@dh_mutexes[n] = Mutex.new unless @@dh_mutexes[n] 
          return @@dh_mutexes[n]
        end

        def getAll
          h = {}
          h['dh'] = getAllDH()
          begin
            @@our_CA = OpenSSL::X509::Certificate.new(File.read CACERT)
            h['ca'] = @@our_CA.to_h
          rescue Errno::ENOENT
          rescue OpenSSL::X509::CertificateError
            h['ca'] = {'err' => $!}
          end
          h['certs'] = getAllCerts()
          return h
        end

        def getAllCerts
          h = {}
          Dir.glob CERTDIR + '/*.crt' do |certfile|
            name = File.basename(certfile).sub(/\.crt$/, '')
            keyfile = KEYDIR + '/' + name + '.key'
            begin
              certobj = OpenSSL::X509::Certificate.new(File.read certfile)
              signed_by_our_CA = false
              signed_by_our_CA = certobj.verify(@@our_CA.public_key) if
                  @@our_CA.respond_to? :public_key
              h[name] = {
                  'cert'              => certobj.to_h, 
                  'private_key'       => false,
                  'signed_by_our_CA'  => signed_by_our_CA
              }
            rescue OpenSSL::X509::CertificateError
              h[name] = {'cert' => {'err' => $!}} 
            end

            # CRL:
            # very simple match by filename, no OpenSSL check 
            # (was made at file upload... somewhat :-P) 
            if File.readable? "#{CERTDIR}/#{name}.crl"
              h[name]['crl'] = "#{name}.crl"
            end
            
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

        def getAllDH
          dh_h = {}
          n = nil
          #@@dh_mutexes.each_pair do |n, mutex|
          #  if mutex.locked?
          #    dh_h["dh#{n}.pem"] = {'being_created' => true, 'size' => n} 
          #  end
          #end
          KEY_SIZES.each do |n|
            dh_file = "dh#{n}.pem"
            dh_file_fullpath = File.join(DIR, dh_file) 
            dh_h[dh_file] = {} unless dh_h[dh_file]
            if @@dh_mutexes[n] and @@dh_mutexes[n].respond_to? :locked?
              dh_h[dh_file]['being_created'] = @@dh_mutexes[n].locked? 
            else
              dh_h[dh_file]['being_created'] = false
            end
            begin
              dh_h[dh_file]['size'] = 
                  dh(dh_file_fullpath).params['p'].to_i.to_s(2).length
            rescue NoMethodError
              dh_h[dh_file]['err'] = 'no valid data'
            end
          end
          return dh_h
        end

        def dh(n_or_file) 
          dh_ = nil
          begin
            if n_or_file.kind_of? Numeric or n_or_file.to_i > 0
              dh_ = OpenSSL::PKey::DH.new(
                  File.read(DIR + '/dh' + n_or_file.to_s + '.pem')
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

        include ERB::Util

        def x509_Name_Hash_to_html_address(h)
          a = []
          a << (html_escape h['O'])                                     if
              h['O']  =~ /\S/
          a <<
    "<span style=\"font-style:italic;\">#{html_escape h['OU']}</span>"  if
              h['OU'] =~ /\S/
          s = ''
          s << (html_escape h['L'])                                     if
              h['L']  =~ /\S/
          s << "&nbsp;(#{html_escape h['ST']})"                         if
              h['ST'] =~ /\S/
          a << s                                                        if
              s       =~ /\S/
          a << (html_escape h['C'])                                     if
              h['C'] =~ /\S/
          return a.join(', ')
        end

      end

    end
  end
end

