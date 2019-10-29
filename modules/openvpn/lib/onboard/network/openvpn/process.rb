require 'digest/md5'

# TODO: get rid of this class i.e. get rid of portable_id

class OnBoard
  module Network
    module OpenVPN
      class Process < System::Process
        attr_reader :portable_id
        def initialize(pid)
          super(pid)
          if @env['PWD'] and @env['PWD'].kind_of? String
            @portable_id = Digest::MD5.hexdigest(
                @env['PWD'] + "\0" + @cmdline_raw
            )
          else
            @portable_id = Digest::MD5.hexdigest(@cmdline_raw)
          end
        end
      end
    end
  end
end

