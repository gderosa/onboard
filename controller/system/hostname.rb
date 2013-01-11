require 'onboard/system/hostname'

class OnBoard
  class Controller

    get "/system/hostname.:format" do
      hostname = System::Hostname.get
      format(
        :path     => 'system/hostname',
        :objects  => hostname
      )
    end

    put "/system/hostname.:format" do
      System::Hostname.set params[:hostname]
      System::Hostname.be_resolved 
      redirect request.path_info 
    end

  end
end
