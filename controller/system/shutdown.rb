require 'onboard/system/shutdown'

class OnBoard
  class Controller

    get "/system/shutdown.html" do
      format(
        :path     => 'system/shutdown',
        :title    => 'Shutdown and Reboot'
      )
    end

    post "/system/shutdown/:action.:format" do
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
