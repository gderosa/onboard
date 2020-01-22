require 'sinatra/base'

require 'onboard/network/access-control/chilli'

class OnBoard

  class Controller < Sinatra::Base

    get '/network/access-control/chilli.:format' do
      format(
        :module => 'chilli',
        :path => '/network/access-control/chilli',
        :format => params[:format],
        :objects  => CHILLI_CLASS.getAll(),
        :title => "Chilli Controller"
      )
    end

    put '/network/access-control/chilli.:format' do
      # NOTE: assumption: one operation at a time
      # TODO: DRY
      if params['stop'] =~ /\S/
        iface = params['stop'].strip
        chilli = CHILLI_CLASS.getAll().detect do |x|
          x.conf['dhcpif'] == iface and x.running? and x.managed?
        end
        if chilli
          if params['restore_interface'] == 'on'
            msg = chilli.stop(:restore => true)
          else
            msg = chilli.stop
          end
        end
      elsif params['start'] =~ /\S/
        iface = params['start'].strip
        chilli = CHILLI_CLASS.getAll().detect do |x|
          x.conf['dhcpif'] == iface and (not x.running?) and x.managed?
        end
        if chilli
          if params['save_interface'] == 'on'
            msg = chilli.start(:save => true)
          else
            msg = chilli.start
          end
        end
      elsif params['restart'] =~ /\S/
        iface = params['restart'].strip
        chilli = CHILLI_CLASS.getAll().detect do |x|
          x.conf['dhcpif'] == iface and x.running? and x.managed?
        end
        msg = chilli.restart if chilli
      end
      unless msg
        msg = {
          :ok => true,
          :warn => 'nothing done'
        }
      end
      format(
        :module   => 'chilli',
        :path     => '/network/access-control/chilli',
        :format   => params[:format],
        :objects  => CHILLI_CLASS.getAll(),
        :msg      => msg,
        :title => "Chilli Controller"
      )
    end

    post '/network/access-control/chilli.:format' do
      msg = {}
      begin
        chilli = CHILLI_CLASS.create_from_HTTP_request(params)
        chilli.conffile = "#{CHILLI_CLASS::CONFDIR}/current/chilli.conf.#{chilli.conf['dhcpif']}"
        chilli.write_conffile
        chilli.validate_conffile(:raise_exception => true)
        #raise CHILLI_CLASS::BadRequest, 'Invalid configuration!' unless chilli.validate_conffile # for whatever is not already checked by Chilli::validate_HTTP_creation
        status(201) # HTTP Created
        headers(
            'Location' =>
  "#{request.scheme}://#{request.host}:#{request.port}/network/access-control/chilli/#{chilli.conf['dhcpif']}.#{params[:format]}"
        )
        msg = {:ok => true}
        chilli.start if params['start_now'] == 'on'
      rescue CHILLI_CLASS::BadRequest
        status 400
        msg = {:err => $!}
      end
      format(
        :module => 'chilli',
        :path => '/network/access-control/chilli',
        :format => params[:format],
        :objects  => CHILLI_CLASS.getAll(),
        :msg => msg,
        :title => 'Chilli Controller'
      )
    end

    get '/network/access-control/chilli/:ifname.:format' do
      all = CHILLI_CLASS.getAll()
      chilli_object = all.detect{|x| x.conf['dhcpif'] == params[:ifname]}
      if chilli_object
        format(
          :module => 'chilli',
          :path => '/network/access-control/chilli/ifconfig',
          :format => params[:format],
          :objects  => chilli_object,
          :title => "Chilli Controller: #{params[:ifname]}"
        )
      else
        not_found
      end
    end

    put '/network/access-control/chilli/:ifname.:format' do
      all = CHILLI_CLASS.getAll()
      chilli = all.detect{|x| x.conf['dhcpif'] == params[:ifname]}
      chilli_new = nil
      msg = {}
      if chilli
        begin
          chilli_new = CHILLI_CLASS.create_from_HTTP_request(params)
          chilli_new.conf.each_pair do |key, val|
            chilli.conf[key] = val unless key =~ /secret|passwd/ or key == 'macauth'
          end

          # TODO: this logic should better be under lib/
          # TODO: as it happens on creation (post)

          # passwords are treated differently
          if params['conf']['radiussecret'].length > 0
            chilli.conf['radiussecret'] = params['conf']['radiussecret']
          end

          if
              !chilli.conf['uamsecret'] or
              chilli.conf['uamsecret'].length == 0 or
              (chilli.conf['uamsecret'] == params['old_conf']['uamsecret'])
            if  params['verify_conf']['uamsecret'] ==
                params['conf']['uamsecret']
              chilli.conf['uamsecret'] = params['conf']['uamsecret']
            else
              raise CHILLI_CLASS::BadRequest, "UAM passwords do not match!"
            end
          else
            raise CHILLI_CLASS::BadRequest, "Wrong UAM password!" unless
                params['conf']['uamsecret'].length == 0 and
                params['verify_conf']['uamsecret'].length == 0
          end

          # macauth (and checkboxes in general) are also special
          if params['conf']['macauth']
            if params['conf']['macpasswd'] == params['verify_conf']['macpasswd']
              chilli.conf['macauth'] = true
              if params['conf']['macpasswd'].size > 0
                chilli.conf['macpasswd'] = params['conf']['macpasswd']
              end
            else
              raise CHILLI_CLASS::BadRequest, "MAC-Auth passwords do not match!"
            end
          else
            chilli.conf.delete 'macauth'
            chilli.conf.delete 'macpasswd'
          end

          # ########
          chilli.write_tmp_conffile_and_validate(:raise_exception => true)
          chilli.write_conffile
          chilli.restart if chilli.running? and params['do_not_restart'] != 'on'
        rescue CHILLI_CLASS::BadRequest
          status 400
          msg[:err] = $!
          msg[:ok] = false
        end

        # refresh
        all = CHILLI_CLASS.getAll()
        chilli = all.detect{|x| x.conf['dhcpif'] == params[:ifname]}

        format(
          :module => 'chilli',
          :path => '/network/access-control/chilli/ifconfig',
          :format => params[:format],
          :objects  => chilli,
          :msg => msg,
          :title => "Chilli Controller: #{params[:ifname]}"
        )
      else
        not_found
      end
    end


    delete '/network/access-control/chilli/:ifname.:format' do
      params[:ifname].strip!
      msg = {}
      chilli = CHILLI_CLASS.getAll.detect do |x|
        x.conf['dhcpif'].strip == params[:ifname]
      end
      if chilli
        if chilli.managed?
          if chilli.running?
            msg = chilli.stop
          else
            msg[:ok] = true
          end
          if msg[:ok]
            # we should have file permission...
            if (FileUtils.rm chilli.conffile)
              status 200 # OK (do nothing)
              redirection = "/network/access-control/chilli.#{params[:format]}"
              status(303)                       # HTTP "See Other"
              headers('Location' => redirection)
              # altough the client will move, an entity-body is always returned
              format(
                :path     => '/303',
                :format   => params[:format],
                :objects  => redirection
              )
            else
              status 500 # internal Server Error
              msg[:err] = $!
              msg[:ok] = false
              format(
                :path     => '/500',
                :format   => params[:format],
                :msg      => msg
              )
            end
          end
        else
          status 403 # Forbidden

        end
      else
        not_found
      end
    end

  end

end
