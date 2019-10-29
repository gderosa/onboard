require 'onboard/extensions/string'
require 'onboard/extensions/digest'

module Digest

  module Instance
    def salted_digest(str='', salt=:auto)
      if salt == :auto
        salt = String.random_binary(digest_length)
      end
      digest(str + salt) + salt
    end
    def salted_hexdigest(str, salt)
      Digest.hexencode(salted_digest(str, salt))
    end
    def salted_base64digest(str, salt)
      [salted_digest(str, salt)].pack('m0')
    end
  end

  class Class
    def self.salted_digest(str, salt=:auto, *args)
      new(*args).salted_digest(str, salt)
    end
    def self.salted_hexdigest(str, salt=:auto, *args)
      new(*args).salted_hexdigest(str, salt)
    end
    def self.salted_base64digest(str, salt=:auto, *args)
      new(*args).salted_base64digest(str, salt)
    end
  end

end
