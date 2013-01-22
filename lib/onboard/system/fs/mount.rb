class OnBoard
  module System

    autoload :Command, 'onboard/system/command'

    module FS
      class Mount

        def initialize(h)
          @mount_point = h[:mount_point]
        end
    
        def writable?
          system "sudo touch #{@mount_point} > /dev/null 2>&1"
        end  

        def readonly?
          not writable?
        end

        def must_be_writable!
          raise Errno::EROFS unless writable?
        end

        def remount!(*opts) 
          optstr = ( %w{remount} + opts.map{|x| x.to_s} ).join(',') 
          Command.send_command "mount #{@mount_point} -o #{optstr}", :sudo
        end
        alias remount remount!

      end
  
    end
  end
end

