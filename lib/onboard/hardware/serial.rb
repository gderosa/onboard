class OnBoard
  module Hardware
    module Serial

      class << self

        def ls
          list            = []
          base_node_paths = []
          File.foreach '/proc/tty/drivers' do |line|
            # http://lwn.net/images/pdf/LDD3/ch18.pdf
            driver,
            base_node_path,
            major,
            minors,
            type =
                line.strip.split(/\s+/)
            if type == 'serial'
              base_node_paths << base_node_path
                  # base_node_path is like /dev/ttyS or /dev/ttyUSB
            end
          end
          base_node_paths.each do |base_node_path|
            node_paths    = []
            glob_pattern  = "#{base_node_path}*"
            regexp        = /^#{base_node_path}[0-9]?$/
            Dir.glob(glob_pattern) do |node_path|
              node_paths << node_path if node_path =~ regexp
            end
            list += node_paths.sort
          end
          return list
        end
        alias all ls

      end

    end
  end
end

if $0 == __FILE__
  require 'pp'
  pp OnBoard::Hardware::Serial.all
end
