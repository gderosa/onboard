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

  get %r{/system/logs/(.*)\.raw} do
    logid = params['captures'].first
      # Could be a full path or an identifying basname,
      # however, leading / is stripped from full paths url-encoded in the (.*)
    potential_absolute_path = File.join '/', logid
    if potential_absolute_path.start_with? OnBoard::LOGDIR
      path = potential_absolute_path
    else
      # Require "registration" for logs outside ~/.onboard/var/log
      hash = OnBoard::System::Log.getAll.detect do |h|
        h['id'] == logid or h['path'] == (File.join '/', logid)
      end
      not_found if not hash
      path = hash['path']
    end
    attachment(path)
    content_type 'text/plain'
    if File.readable? path
      `cat #{path}`
    else
      `sudo cat #{path}`
    end
  end

  # by id
  get %r{/system/logs/(.*)\.([a-z]+)} do
    logid, fmt = params['captures']
    # Leading / is stripped from logid/path
    hash = OnBoard::System::Log.getAll.detect {|h| h['id'] == logid or h['path'] == (File.join '/', logid)}
    pass if not hash
    log = OnBoard::System::Log.new(hash)
    format(
      :path     => 'system/logs',
      :format   => fmt,
      :objects  => log,
      :title    => "Log: #{logid}"
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
