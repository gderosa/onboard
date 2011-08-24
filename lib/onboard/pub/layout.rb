require 'fileutils'
require 'yaml'

class OnBoard
  module Pub
    module Layout
      FILESDIR        = File.join OnBoard::RWDIR, 'var/www/pub'
      CONFDIR         = File.join OnBoard::CONFDIR, 'webif/pub' 
      CONFFILE        = File.join CONFDIR, 'layout.yml'
      CUSTOMTEXTFILE  = "#{FILESDIR}/custom_text.html"

      class << self

        def read_conf
          conf = {}
          if File.exists? CONFFILE
            conf = YAML.load File.read CONFFILE
          end
          if File.exists? CUSTOMTEXTFILE
            conf['custom_text'] = File.read CUSTOMTEXTFILE
          end
          return conf
        end

        def logo_file
          conf = read_conf
          File.join FILESDIR, conf['logo'] if conf['logo'] # else return nil ^_-
        end

        def update(params)
          FileUtils.mkdir_p FILESDIR
          FileUtils.mkdir_p CONFDIR

          conf = read_conf

          if params['delete'] and params['delete']['logo']
            conf.delete 'logo'
          elsif params['logo']
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

          if params['delete'] and params['delete']['custom_text']
            conf.delete 'custom_text'
            FileUtils.rm CUSTOMTEXTFILE if File.exists? CUSTOMTEXTFILE
          elsif  params['custom_text'].respond_to? :length and 
              params['custom_text'].length >    0           # useful?      
            File.open(CUSTOMTEXTFILE, 'w') do |f|
              f.write params['custom_text']
            end
          end

          File.open(CONFFILE, 'w') do |f|
            f.write YAML.dump conf
          end
        end

      end

    end
  end
end
