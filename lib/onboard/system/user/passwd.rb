require 'etc'
require 'open3'

require 'onboard/exceptions'
require 'onboard/system/user/passwd/status'
require 'onboard/system/fs'

class OnBoard
  module System
    class User
      class Passwd

        attr_reader :entry, :status

        def initialize(x=Process.uid)
          @entry = case x
          when Integer
            Etc.getpwuid x
          when String, Symbol
            Etc.getpwnam x.to_s
          when Struct::Passwd
            x
          end
          @status = Status.new @entry
        end

        def locked?
          # p @status.fields
          @status.fields[1] == 'L' # man 1 passwd ## @ --status
        end

        # TODO: change_from_HTTP_request() is horrible, turn this into
        # change(newpasswd) and extract from HTTP params within the
        # Sinatra Controller. This should be done for many modules and classes
        # throughout the OnBoard source tree...
        #
        def change_from_HTTP_request(params)
          was_readonly = System::FS.root.readonly?
          System::FS.root.remount 'rw' if was_readonly
          System::Command.send_command(
            'chpasswd',
            :sudo,
            :stdin => "#{name}:#{params['newpasswd']}",
            :raise => ServerError
          )
          System::FS.root.remount 'ro' if was_readonly
        end

        def method_missing(id, *args, &blk)
          @entry.send id, *args, &blk
        end

      end
    end
  end
end
