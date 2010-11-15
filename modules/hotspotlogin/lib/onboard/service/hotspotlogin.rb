require 'yaml'
require 'hotspotlogin' # http://rubygems.org/gems/hotspotlogin

require 'onboard/system/command'
require 'onboard/system/process'

class OnBoard
  module Service
    class HotSpotLogin # TODO: should be a module... no instances...

      CONFFILE = File.join CONFDIR, 'current/hotspotlogin.conf.yaml'
      DEFAULT_CONFFILE = File.join(
        ROOTDIR, '/etc/defaults/hotspotlogin.conf.yaml')

      unless Dir.exists? File.dirname CONFFILE
        FileUtils.mkdir_p File.dirname CONFFILE
      end
        
      unless File.exists? CONFFILE
        FileUtils.cp DEFAULT_CONFFILE, CONFFILE
      end

      VARRUN = '/var/run' # take advantage of tmpfs (strongly suggested)
      VARLOG = OnBoard::LOGDIR # do we need a subdirectory?
      PIDFILE = File.join VARRUN, 'onboard-hotspotlogin.pid'
      LOGFILE = File.join VARLOG, 'hotspotlogin.log'
      SAVEFILE = "#{CONFDIR}/saved/hotspotlogin.yaml"

      class BadRequest < ArgumentError; end
      class AlreadyRunning < RuntimeError; end

      class << self
        
        def save # use YAML, not Marshal, this time
          unless Dir.exists? File.dirname SAVEFILE
            FileUtils.mkdir_p File.dirname SAVEFILE
          end
          File.open SAVEFILE, 'w' do |f|
            f.write data.to_yaml
          end
        end

        def restore
          if File.readable? SAVEFILE
            saved_data = YAML.load(File.read SAVEFILE)
            File.open CONFFILE, 'w' do |f|
              f.write saved_data['conf'].to_yaml
            end
            if saved_data['running'] and not running?
              start!
            end
          end
        end

        def running?
          return false unless File.exists? PIDFILE
          pid = File.read(PIDFILE).to_i
          return false unless Dir.exists? "/proc/#{pid}"
begin # THIS IS DIIIIIRTY! # TODO? use OnBoard::System::Process#kill stop!()
          process = System::Process.new File.read(PIDFILE).to_i
          return true if 
              process.cmdline[0] and
              (File.basename(process.cmdline[0]) =~ /^hotspotlogin(\.rb)?$/)
          return true if
              process.cmdline[1] and
              (File.basename(process.cmdline[1]) =~ /^hotspotlogin(\.rb)?$/)
          return false
rescue
  return false
end
        end

        def data
          {
            'defaults'  => read_defaults,
            'conf'      => read_conf,
            'running'   => running?
          }
        end

        def start!
          raise AlreadyRunning if running?
          msg = System::Command.run "hotspotlogin --daemon --conf #{CONFFILE} --pid #{PIDFILE} --log #{LOGFILE}"
          return msg
        end

        def stop!
          Process.kill 'TERM', File.read(PIDFILE).to_i
        end

        def restart!
          stop! if running?
          start!
        end

        def read_conf
          YAML.load(File.read(CONFFILE))
        end

        def read_defaults
          YAML.load(File.read(DEFAULT_CONFFILE))
        end

        def change_from_HTTP_request!(params)
          conf_h = read_conf
          conf_h['port']      = params['port'].to_i if params['port']
          conf_h['interval']  = params['interval'].to_i if params['interval']

          if 
              conf_h['uamsecret'] and 
              conf_h['uamsecret'].length > 0 and
              conf_h['uamsecret'] != params['uamsecret_old'] and
              ( 
                params['uamsecret'].length > 0 or
                params['uamsecret_verify'].length > 0
              )
            raise BadRequest, 'Wrong UAM password!'
          elsif params['uamsecret'] != params['uamsecret_verify']
            raise BadRequest, 'UAM passwords do not match!'
          end
          if params['uamsecret'].length > 0
            conf_h['uamsecret'] = params['uamsecret']
          else 
            # extra check of the old password (if any): BadRequest was not 
            # raised in this case
            if conf_h['uamsecret'] and conf_h['uamsecret'].length > 0
              if conf_h['uamsecret'] == params['uamsecret_old']
                conf_h['uamsecret'] = nil
              end
            else
              conf_h['uamsecret'] = nil
            end
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

