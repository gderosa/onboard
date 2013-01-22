require 'onboard/system/shutdown'

class OnBoard
  class Controller

    get "/system/shutdown.html" do
      format(
        :path     => 'system/shutdown',
        :title    => 'Shutdown and Reboot'
      )
    end

    post "/system/shutdown.:format" do
      unless params['confirm']
        status 204 # No Content
        halt
      end
      begin
        System::Shutdown.send params[:action]
      rescue NoMethodError
        not_found
      end
      format(
        :path     => 'system/shutdown/action',
        :title    => params[:action].capitalize + 'ing&hellip;'
      )
    end

  end
end
