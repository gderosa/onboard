require 'digest/md5' 

class OnBoard
  module Network
    module OpenVPN
      class Process < System::Process
        attr_reader :portable_id
        def initialize(pid)
          super(pid)
          @portable_id = Digest::MD5.hexdigest(
              @env['PWD'] + "\0" + @cmdline_raw
          )
        end
      end
    end
  end
end

