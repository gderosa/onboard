#require 'fileutils'

#require 'onboard/extensions/ipaddr'
#require 'onboard/system/process'
#require 'onboard/network/interface'
#require 'onboard/network/interface/ip'

class OnBoard
  module Network
    module AP
      def self.set_config(ifname, params)
        File.open CONFDIR + '/new/' + ifname + '.conf', 'w' do |f|
          params.each_pair do |k, v|
            f.puts "#{k}=#{v}"
          end
        end
      end
      def self.save
      end
      def self.restore
      end
    end
  end
end

