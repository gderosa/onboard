module Digest
  autoload :MD5, 'digest/md5'
end

class OnBoard
  class Passwd

    def self.change_from_HTTP_request(params)
      unless check(params['oldpasswd'])
        return {
          :ok => false,
          :err => 'Wrong password!',
          :status_http => 401 # Unauthorized
        }
      end
    end

    def self.check(passwd)
      return false
    end

    def initialize(passwd)
      @md5 = passwd ? Digest::MD5.hexdigest(passwd) : nil
    end

  end
end
