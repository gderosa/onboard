require 'fileutils'
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

      VARRUN    = '/var/run' # take advantage of tmpfs (strongly suggested)
      VARLOG    = OnBoard::LOGDIR # do we need a subdirectory?
      PIDFILE   = File.join VARRUN, 'onboard-hotspotlogin.pid'
      LOGFILE   = File.join VARLOG, 'hotspotlogin.log'
      SAVEFILE  = "#{CONFDIR}/saved/hotspotlogin.yaml"
      VARWWW    = "#{RWDIR}/var/www/hotspotlogin"
      CUSTOMTEXT_HTMLFRAGMENT   =
                  "#{VARWWW}/custom_text.html"
      CUSTOMFOOTER_HTMLFRAGMENT =
                  "#{VARWWW}/custom_footer.html"
      
      # TODO: move this in some specific place
      unless Dir.exists? File.dirname CONFFILE
        FileUtils.mkdir_p File.dirname CONFFILE
      end        
      unless File.exists? CONFFILE
        FileUtils.cp DEFAULT_CONFFILE, CONFFILE
      end
      FileUtils.mkdir_p VARWWW unless Dir.exists? VARWWW

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
          FileUtils.chmod 0640, SAVEFILE
        end

        def restore
          if File.readable? SAVEFILE
            saved_data = YAML.load(File.read SAVEFILE)
            File.open CONFFILE, 'w' do |f|
              f.write saved_data['conf'].to_yaml
            end
            FileUtils.chmod 0640, CONFFILE
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
          # hotspotlogin should provide its defaults in some way
          # to non-Ruby programs too: maybe --dump-defaults-yaml ?
          ::HotSpotLogin::DEFAULT_CONFIG.update(      # "upstream" defaults
              YAML.load(File.read(DEFAULT_CONFFILE))) # "our" defaults
        end

        def change_from_HTTP_request!(params)
          conf_h = read_conf
          conf_h['port']      = # don't use priviliged ports 
            params['port'].to_i if params['port'].to_i > 1024
          conf_h['interval']  = 
            params['interval'].to_i if params['interval'].to_i > 0

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
          
          # logo
          # TODO: delete stale files or manage a collection/library of logos?
          if params['delete'] and params['delete']['logo'] == 'on'
            conf_h['logo'] = nil
          elsif params['logo'] 
            logo_path = "#{VARWWW}/#{params['logo'][:filename]}"
            FileUtils.mv(params['logo'][:tempfile], logo_path) 
            conf_h['logo'] = logo_path
          end

          # custom text
          if params['delete'] and params['delete']['custom_text']
            if File.file? CUSTOMTEXT_HTMLFRAGMENT
              File.open CUSTOMTEXT_HTMLFRAGMENT, 'w' do |f|
                # do nothing, flush file
              end
            end
          elsif params['custom_text']
            File.open CUSTOMTEXT_HTMLFRAGMENT, 'w' do |f|
              f.write params['custom_text']
            end
            conf_h['custom-text'] = CUSTOMTEXT_HTMLFRAGMENT
          end

          # custom footer
          if params['delete'] and params['delete']['custom_footer']
            if File.file? CUSTOMFOOTER_HTMLFRAGMENT
              File.open CUSTOMFOOTER_HTMLFRAGMENT, 'w' do |f|
                # do nothing, flush file
              end
            end
          elsif params['custom_footer']
            File.open CUSTOMFOOTER_HTMLFRAGMENT, 'w' do |f|
              f.write params['custom_footer']
            end
            conf_h['custom-footer'] = CUSTOMFOOTER_HTMLFRAGMENT
          end
         
          File.open CONFFILE, 'w' do |f|
            f.write conf_h.to_yaml
          end
          FileUtils.chmod 0640, CONFFILE
        end
      end

    end
  end
end

