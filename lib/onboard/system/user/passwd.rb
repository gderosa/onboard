require 'etc'

class OnBoard
  module System
    class User 
      class Passwd

        autoload :Status, 'onboard/system/user/passwd/status'

        attr_reader :entry, :status

        def initialize(x)
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
          @status.fields[1] == 'L'
        end

        def change_from_HTTP_request(params)
        end

      end
    end
  end
end
