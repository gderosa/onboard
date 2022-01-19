require 'fileutils'
require 'erb'
require 'openssl'
require 'facets/hash'
require 'onboard/crypto/ssl'

class OnBoard
  module Crypto
    module SSL
      module Multi

        SUBDIR = '__multipki__'
        DATADIR = File.join SSL::DATADIR, SUBDIR
        DEFAULTPKIDIR = File.join DATADIR, 'default'

        class << self
          def handle_legacy
            unless File.exists? DATADIR
              FileUtils.mkdir_p DATADIR
            end
            unless File.exists? DEFAULTPKIDIR
              FileUtils.ln_s '..', DEFAULTPKIDIR
            end
          end

          def get_pki_names
            if Dir.exists? DATADIR
              return Dir.entries(DATADIR).select{|entry| entry =~ /^[^\.\s]\S+$/i}
            else
              return []
            end
          end
          alias get_pkis get_pki_names
        end

      end
    end
  end
end
