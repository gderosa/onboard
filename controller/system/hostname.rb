require 'onboard/system/hostname'

class OnBoard
  class Controller

    get "/system/hostname.:format" do
      format(
        :path     => 'system/hostname',
        :objects  => System::Hostname,
        :title    => 'Hostname'
      )
    end

    put "/system/hostname.:format" do
      System::Hostname.set(
        :hostname   => params[:hostname],
        :domainname => params[:domainname]
      )
      System::Hostname.be_resolved
      format(
        :path     => 'system/hostname',
        :objects  => System::Hostname,
        :title    => 'Hostname'
      )
    end

  end
end
