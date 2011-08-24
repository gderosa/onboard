require 'fileutils'
require 'yaml'

class OnBoard
  module Pub
    module Layout
      FILESDIR  = File.join OnBoard::RWDIR, 'var/www/pub'
      CONFDIR   = File.join OnBoard::CONFDIR, 'webif/pub' 
      CONFFILE  = File.join CONFDIR, 'layout.yml'

      class << self

        def read_conf
          if File.exists? CONFFILE
            return YAML.load File.read CONFFILE
          else
            return {}
          end
        end

        def update(params)
          pp params # DEBUG

          FileUtils.mkdir_p FILESDIR
          FileUtils.mkdir_p CONFDIR

          conf = read_conf

          if params['logo']
            FileUtils.cp(
              params['logo'][:tempfile], 
              File.join(
                FILESDIR, 
                params['logo'][:filename]
              )
            )  
            conf['logo']      = params['logo'][:filename]
          end
          conf['logo_link'] = params['logo_link']

          File.open(CONFFILE, 'w') do |f|
            f.write YAML.dump conf
          end
          if  params['custom_text'].respond_to? :length and 
              params['custom_text'].length >    0           # useful?      
            File.open("#{FILESDIR}/custom_text.html", 'w') do |f|
              f.write params['custom_text']
            end
          end
        end

      end

    end
  end
end
