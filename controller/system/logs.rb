require 'sinatra/base'

require 'onboard/system/log'

class OnBoard::Controller

  get "/system/logs.:format" do
    format(
      :path     => 'system/logs',
      :format   => params[:format],
      :objects  => OnBoard::System::Log ) # yes, the class: a way to implement
        # the Singleton pattern without creating "AllLogs"  
  end

  get "/system/logs/:logid.raw" do
    hash = OnBoard::System::Log.getAll.detect {|h| h['id'] == params['logid']}
    not_found if not hash
    attachment(params['logid']) 
    content_type 'text/plain'
    if File.readable? hash['path']
      `cat #{hash['path']}`
    else
      `sudo cat #{hash['path']}` 
    end
  end

  get "/system/logs/:logid.:format" do
    hash = OnBoard::System::Log.getAll.detect {|h| h['id'] == params['logid']}
    not_found if not hash
    log = OnBoard::System::Log.new(hash)
    format(
      :path     => 'system/logs',
      :format   => params[:format],
      :objects  => log
    )
  end

end
