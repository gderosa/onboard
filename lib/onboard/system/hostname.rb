class OnBoard
  module System
    class Hostname # module? shall we have Hostname instances?

      CONFFILE = File.join OnBoard::CONFDIR, 'hostname'
      
      class << self

        def get
          `hostname`.strip
        end

        def set(name)
          Command.send_command "hostname #{name.strip}", :sudo
        end

        def hostname(name=nil)
          name ? set(name) : get
        end

        def save
          File.open(CONFFILE, 'w') {|f| f.write hostname}
        end

        def restore
          hostname File.read CONFFILE
        end

      end

    end
  end
end
