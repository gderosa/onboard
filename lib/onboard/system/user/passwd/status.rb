class OnBoard
  module System
    class User
      class Passwd
        class Status
          attr_reader :fields
          def initialize(passwd_entry)
            @username = passwd_entry.name
            cmd = "passwd --status #{@username}"
            cmd = "sudo #{cmd}" unless ::Process.uid == passwd_entry.uid
            @fields = `#{cmd}`.split
          end
        end
      end
    end
  end
end
