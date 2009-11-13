autoload :OpenSSL, 'openssl'

class OnBoard
  module Crypto
    module SSL

      DIR = OnBoard::ROOTDIR + '/etc/config/crypto/ssl'

      class << self

        # Mutual exclusion for threads creating Diffie-Hellman parameters
        def dh_mutex(n)
          @@dh_mutexes = {} unless class_variable_defined? :@@dh_mutexes
          @@dh_mutexes[n] = Mutex.new unless @@dh_mutexes[n] 
          return @@dh_mutexes[n]
        end

        def getAll
          h = {}
          h['dh'] = getAllDH()
          return h
        end

        def getAllDH
          dh_h = {}
          Dir.glob(DIR + '/dh*.pem').each do |dh_file|
            dh_h[File.basename dh_file] = {
              'size' => dh(dh_file).params['p'].to_i.to_s(2).length
            }
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
