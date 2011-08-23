require 'fileutils'
require 'yaml'

class OnBoard
  module Pub
    module Layout
      FILESDIR  = File.join OnBoard::RWDIR, 'var/www/pub'
      CONFDIR   = File.join OnBoard::CONFDIR, 'webif/pub' 
      CONFFILE  = File.join CONFDIR, 'layout.yml'

      class << self

        def update(params)
          pp params # DEBUG

          FileUtils.mkdir_p FILESDIR
          FileUtils.mkdir_p CONFDIR

          conf = {}

          FileUtils.cp(
            params['logo'][:tempfile], 
            File.join(
              FILESDIR, 
              params['logo'][:filename]
            )
          ) 
          conf['logo'] = params['logo'][:filename]

          File.open(CONFFILE, 'w') do |f|
            f.write YAML.dump conf
          end

        end

      end

    end
  end
end
