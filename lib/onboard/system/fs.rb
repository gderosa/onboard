class OnBoard
  module System
    module FS

      autoload :Mount, 'onboard/system/fs/mount'

      class << self
    
        def writable?(mount_point)
          Mount.new(:mount_point=>mount_point).writable?
        end  

        def need_writable!(mount_point)
          raise Errno::EROFS unless writable?(mount_point) 
        end

        def writable_root?;       writable?(      '/'); end
        
        def need_writable_root!;  need_writable!( '/'); end

      end
  
    end
  end
end

