require 'digest/md5'

require 'onboard/exceptions'
require 'onboard/extensions/string' # patched String#== is important here!

class OnBoard
  # This refers to the Web UI password(s?).
  # For Unix login passwords look at the OnBoard::System::User namespace.
  module Passwd
    # Currently, just one user: admin .
    PASSWD_DIR = OnBoard::CONFDIR + '/self/passwd'
    ADMIN_PASSWD_FILE = PASSWD_DIR + '/admin.md5.dat'
    DEFAULT_ADMIN_USERNAME = 'admin'
    DEFAULT_ADMIN_PASSWD = 'admin'

    def self.change_from_HTTP_request(params)
      FileUtils.mkdir_p PASSWD_DIR unless Dir.exists? PASSWD_DIR
      File.open ADMIN_PASSWD_FILE, 'w' do |f|
        f.write Digest::MD5.digest params['newpasswd']
      end
    end

    def self.check_pass(passwd)
      if File.exists? ADMIN_PASSWD_FILE
        Digest::MD5.digest(passwd) == File.read(ADMIN_PASSWD_FILE)
      else
        passwd == DEFAULT_ADMIN_PASSWD
      end
    end

    # An alias, until other users will exist
    def self.check_admin_pass(passwd)
      self.check_pass(passwd)
    end

  end
end
