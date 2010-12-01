require 'digest/md5'

module Digest
  class MD5
    
    LENGTH = 256

    alias digest_orig digest

    def digest(str, opts_h=nil)
      if opts_h
        if opts_h[:salt]
          salt = opts_h[:salt]
          return digest_orig(str + salt) + salt
        end
      else
        return digest_orig digest str
      end
    end

  end
end
