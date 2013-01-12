require 'onboard/system/hostname'

class OnBoard
  class Controller

    get "/system/hostname.:format" do
      format(
        :path     => 'system/hostname',
        :objects  => System::Hostname
      )
    end

    put "/system/hostname.:format" do
      System::Hostname.set params[:hostname]
      System::Hostname.be_resolved
      format(
        :path     => 'system/hostname',
        :objects  => System::Hostname
      )
    end

  end
end
