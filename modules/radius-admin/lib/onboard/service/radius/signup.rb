require 'yaml'
require 'facets/hash'

class OnBoard
  module Service
    module RADIUS
      module Signup

        CONFFILE = File.join RADIUS::CONFDIR, 'signup.yml'

        DEFAULT_CONFIG = {
          'enable'          => false,
          'enable_selfcare' => false,
          'check'             => {
            'Password-Type'     => 'SSHA1-Password',
            'Auth-Type'         => ''
          },
          'reply'           => {},
        }

        def self.get_config
          if File.exists? CONFFILE
            return DEFAULT_CONFIG.deep_merge YAML.load File.read CONFFILE
          else
            return DEFAULT_CONFIG
          end
        end

        def self.update_config(params)
          FileUtils.mkdir_p CONFDIR # just in case
          config_data = {
            'enable'          => ( params['enable']           ? true : false )  ,
            'enable_selfcare' => ( params['enable_selfcare']  ? true : false )  ,
            'check'           => params['check']                                ,
            'reply'           => params['reply']                                ,
            'mandatory'       => params['mandatory']
          }
          File.open CONFFILE, 'w' do |f|
            f.write config_data.to_yaml
          end
        end

      end
    end
  end
end

