require 'sinatra/base'

require 'onboard/system/log'

class OnBoard::Controller

  get %r{/system/logs} do
    OnBoard::System::Log.load
    pass
  end

  get "/system/logs.:format" do
    format(
      :path     => 'system/logs',
      :format   => params[:format],
      :objects  => OnBoard::System::Log , # yes, the class: a way to implement
        # the Singleton pattern without creating "AllLogs"  
      :title    => 'Logs'
    )
  end

  get "/system/logs/:logid.raw" do
    hash = OnBoard::System::Log.getAll.detect do |h| 
      h['id'] == params['logid'] or h['path'] == params['logid']
    end
    not_found if not hash
    attachment(params['logid']) 
    content_type 'text/plain'
    if File.readable? hash['path']
      `cat #{hash['path']}`
    else
      `sudo cat #{hash['path']}` 
    end
  end

  # by id
  get "/system/logs/:logid.:format" do
    hash = OnBoard::System::Log.getAll.detect {|h| h['id'] == params['logid']}
    pass if not hash
    log = OnBoard::System::Log.new(hash)
    format(
      :path     => 'system/logs',
      :format   => params[:format],
      :objects  => log,
      :title    => "Log: #{params['logid']}"
    )
  end

  # by path ## url_encode-ing is suggested to not confuse navbar
  # example: /system/logs/%2Fvar%2Flog%2Fmessages.html
  get %r{/system/logs/(.*)\.([\w\d]+)} do
    path, fmt = params[:captures]
    # p path # DEBUG
    hash = OnBoard::System::Log.getAll.detect {|h| h['path'] == path}
    not_found if not hash
    log = OnBoard::System::Log.new(hash)
    if fmt == 'raw'
      attachment(File.basename path)
      content_type 'text/plain'
      send_file path
    else
      format(
        :path     => 'system/logs',
        :format   => fmt,
        :objects  => log,
        :title    => "Log: #{path}" 
      )
    end
  end

end
