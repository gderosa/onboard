require 'fileutils'
require 'yaml'

class OnBoard
  module Pub
    module Layout
      FILESDIR        = File.join OnBoard::RWDIR, 'var/www/pub'
      CONFDIR         = File.join OnBoard::CONFDIR, 'webif/pub'
      CONFFILE        = File.join CONFDIR, 'layout.yml'

      class << self

        def read_conf
          conf = {}
          if File.exists? CONFFILE
            conf = YAML.load File.read CONFFILE
          end
          return conf
        end

        # TODO? a Logo namespace?
        def logo_file
          conf = read_conf
          File.join FILESDIR, conf['logo'] if conf['logo'] # else return nil ^_-
        end
        def logo_basename
          conf = read_conf
          conf['logo'] if conf['logo'] # else return nil ^_-
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
          elsif  params['custom_text'].respond_to? :length and
              params['custom_text'].length >    0           # useful?
            conf['custom_text'] = params['custom_text']
          end

          File.open(CONFFILE, 'w') do |f|
            f.write YAML.dump conf
          end
        end

      end

    end
  end
end
