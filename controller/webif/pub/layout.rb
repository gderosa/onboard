require 'onboard/pub/layout'

class OnBoard
  class Controller

    title = 'Public Interface web layout'

    get '/webif/pub/layout.:format' do 
      format(
        :path => '/webif/pub/manage_layout', 
            # not an erubis layout file, hence the name, to avoid confusion ;-)
        :format => params[:format],
        :objects => OnBoard::Pub::Layout.read_conf,
        :title  => title
      )
    end

    get '/webif/pub/logo_preview' do
      send_file OnBoard::Pub::Layout.logo_file
    end

    put '/webif/pub/layout.:format' do 
      OnBoard::Pub::Layout.update params
      format(
        :path => '/webif/pub/manage_layout', 
            # not an erubis layout file, hence the name, to avoid confusion ;-)
        :format => params[:format],
        :objects => OnBoard::Pub::Layout.read_conf,
        :title  => title
      )
    end
   
  end
end
