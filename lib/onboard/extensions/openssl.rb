autoload :Digest, 'digest'

require 'openssl'

module OpenSSL
  module X509

    class Name
      # So you can check, for example, whether a CRL was issued by a given CA,
      # if you have its certificate.
      #
      #     crl     = OpenSSL::X509::CRL.new          File.read 'crl.pem'
      #     cacert  = OpenSSL::X509::Certificate.new  File.read 'ca.crt'
      #
      #     crl.issuer == cacert.subject #=> true or false
      #
      def ==(other)
        self.hash == other.hash # other methods: to_a, to_s, to_der
      end

      def to_h
        h = {}
        self.to_a.each do |elem|
          if elem[1].encoding == Encoding::ASCII_8BIT
            elem[1].force_encoding 'utf-8'
          end # lacking info on a raw byte sequence, utf8 encoding is assumed
          h[elem[0]] = elem[1] # we loose elem[2] (numeric 'type')
        end
        return h
      end
    end

    class Certificate

      def fingerprint(h={})
        h_default = {
          :digest => :SHA1,
          :hex    => false
        }
        h = h_default.update h
        if h[:hex]
          Digest::const_get(h[:digest])::hexdigest to_der
        else
          Digest::const_get(h[:digest])::digest to_der
        end
      end

      def ca?
        to_h['is_ca']
      end

      def to_h

        h = {
          'not_before'          => not_before(),
          'not_after'           => not_after(),
          'serial'              => serial().to_i,
          'version'             => version() + 1, # X509 version 0x02 -> 3 etc..
          'signature_algorithm' => signature_algorithm(),
          'key_size'            => public_key.size,
          'is_ca'               => false,
          'is_server'           => false,
          'issuer'              => issuer.to_h,
          'subject'             => subject.to_h,
          #'fingerprint'         => { # costly!
          #  'sha1'                => fingerprint(
          #                              :digest => :SHA1, :hex => true),
          #  'md5'                 => fingerprint(
          #                              :digest => :MD5, :hex => true)
          #}
        }

        extensions.each do |ext|
          h['is_ca'] = true if ext.to_a[1] =~ /CA:TRUE/ # and
              # ext.to_a[0] = "basicConstraints"
          h['is_server'] = true if ext.to_a[1] == "SSL Server" # and
              # ext.to_a[0] = "nsCertType"
          # commented conditions should be unnecessary....
        end

        return h
      end
    end
  end
  module PKey
    class RSA
      # Returns key size in bytes
      def size_bytes
        n.to_i.size
            # NOTE: Why something so basic is apparently missing?
      end
      def size_bits
        size_bytes * 8
      end
      def size; size_bits; end
    end
  end
end
