require 'openssl'
require 'onboard/extensions/openssl'

class OnBoard
  module Crypto
    module SSL

      DIR = OnBoard::ROOTDIR + '/etc/config/crypto/ssl'
      KEY_SIZES = [1024, 2048]

      @@dh_mutexes = {} unless class_variable_defined? :@@dh_mutexes

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
            h['ca'] = OpenSSL::X509::Certificate.new(
                File.read DIR + '/ca.crt').to_h
          rescue Errno::ENOENT
          rescue OpenSSL::X509::CertificateError
            h['ca'] = {'err' => $!}
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

      end

    end
  end
end
