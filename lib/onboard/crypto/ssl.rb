class OnBoard
  module Crypto
    module SSL

      # Mutual exclusion for threads creating Diffie-Hellman parameters
      def self.dh_mutex(n)
        @@dh_mutexes = {} unless class_variable_defined? :@@dh_mutexes
        @@dh_mutexes[n] = Mutex.new unless @@dh_mutexes[n] 
        return @@dh_mutexes[n]
      end

      def self.dh_exists?(n)
        File.readable?(
          OnBoard::ROOTDIR + '/etc/config/crypto/ssl/dh' + n.to_s + '.pem'
        )
      end

    end
  end
end
