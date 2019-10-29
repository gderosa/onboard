class OnBoard
  module System
    module FS

      autoload :Mount, 'onboard/system/fs/mount'

      class << self

        def root
          Mount.new(:mount_point => '/')
        end

        def writable?(mount_point)
          Mount.new(:mount_point=>mount_point).writable?
        end

        def need_writable!(mount_point)
          Mount.new(mount_point).must_be_writable!
        end

        def writable_root?;       root.writable?;         end

        def need_writable_root!;  root.must_be_writable!; end

        def mountpoint?(mntpt)
          system "mountpoint -q #{mntpt}"
        end

      end

    end
  end
end

