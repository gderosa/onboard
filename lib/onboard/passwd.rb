require 'digest/md5'
require 'onboard/extensions/string' # patched String#== is important here!

class OnBoard
  module Passwd
    # Currently, just one user: admin .

    PASSWD_DIR = OnBoard::CONFDIR + '/self/passwd'
    ADMIN_PASSWD_FILE = PASSWD_DIR + '/admin.md5.dat'
    DEFAULT_ADMIN_USERNAME = 'admin'
    DEFAULT_ADMIN_PASSWD = 'admin'

    def self.change_from_HTTP_request(params)
      unless self.check_pass(params['oldpasswd'])
        return {
          :ok => false,
          :err => 'Wrong password!',
          :status_http => 401 # Unauthorized
        }
      end
      unless params['newpasswd'] == params['newpasswd2']
        return {
          :ok => false,
          :err => 'Passwords do not match!',
          :status_http => 400
        }
      end
      File.open ADMIN_PASSWD_FILE, 'w' do |f|
        f.write Digest::MD5.digest params['newpasswd']
      end
      return {:ok => true, :info => 'Password successfully updated.'}
    end

    def self.check_pass(passwd)
      if File.exists? ADMIN_PASSWD_FILE
        Digest::MD5.digest(passwd) == File.read(ADMIN_PASSWD_FILE)
      else
        passwd == 'admin'
      end
    end
    
    # An alias, until other users will exist
    def self.check_admin_pass(passwd)
      self.check_pass(passwd)
    end

  end
end
