autoload :YAML, 'yaml'

require 'onboard/system/process'

class OnBoard
  module Service
    class HotSpotLogin

      CONFFILE = File.join CONFDIR, 'current/hotspotlogin.conf.yaml'
      DEFAULT_CONFFILE = File.join CONFDIR, 'defaults/hotspotlogin.conf.yaml'

      # this OnBoard module cannot handle more than one process
      class MultipleInstances < RuntimeError; end

      class BadRequest < ArgumentError; end

      class << self
        def running?
          true
        end

        def data
          {
            'conf' => read_conf,
            'running' => running?
          }
        end

        def read_conf
          YAML.load(File.read(CONFFILE))
        end

        def change_from_HTTP_request!(params)
          conf_h = read_conf
          conf_h['port']      = params['port'].to_i if params['port']

          if 
              conf_h['uamsecret'] and 
              conf_h['uamsecret'].length > 0 and
              conf_h['uamsecret'] != params['uamsecret_old'] and
              params['uamsecret'].length > 0 
            raise BadRequest, 'Wrong UAM password!'
          elsif params['uamsecret'] != params['uamsecret_verify']
            raise BadRequest, 'UAM passwords do not match!'
          end
          if params['uamsecret'].length > 0
            conf_h['uamsecret'] = params['uamsecret']
          else
            conf_h['uamsecret'] = nil
          end
          
          conf_h['userpassword'] = (params['userpassword'] == 'on')
          File.open CONFFILE, 'w' do |f|
            f.write conf_h.to_yaml
          end
        end
      end

    end
  end
end

