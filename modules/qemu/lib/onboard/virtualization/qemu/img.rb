class OnBoard
  module Virtualization
    module QEMU
      class Img
        ROOTDIR = '/home/onboard/files/QEMU'
        class << self

          # for example an image is created at: ~/files/qemu/Win7/Win7.qcow2
          # or ~/files/qemu/Debian/Debian.raw
          def create(h)
            pp h # DEBUG
            raise OnBoard::BadRequest, 'Virtual machine must have a name' unless
                h[:http_params]['name'] and h[:http_params]['name'] =~ /\S/
            name = h[:http_params]['name']
            if h[:http_params]['qemu-img'] and h[:http_params]['qemu-img']['create'] == 'on'
              size_str = h[:http_params]['qemu-img']['size']['G'] + 'G'
              fmt = h[:http_params]['qemu-img']['fmt']
              FileUtils.mkdir_p File.join ROOTDIR, name
              filepath = "#{ROOTDIR}/#{name}/#{name}.#{fmt}"
              System::Command.run(
                  "qemu-img create -f #{fmt} #{filepath} #{size_str}", :raise_BadRequest) 
              return filepath
            end
          end

        end
      end
    end
  end
end

