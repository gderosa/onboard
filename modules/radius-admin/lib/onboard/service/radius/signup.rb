require 'yaml'

class OnBoard
  module Service
    module RADIUS
      module Signup
        CONFFILE = File.join RADIUS::CONFDIR, 'signup.yml'
        def self.update_config(params)
          FileUtils.mkdir_p CONFDIR # just in case
          File.open CONFFILE, 'w' do |f|
            f.write params.to_yaml
          end
        end
      end
    end
  end
end

