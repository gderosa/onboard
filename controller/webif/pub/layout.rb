require 'onboard/pub/layout'

class OnBoard
  class Controller

    title = 'Public Interface web layout'

    get '/webif/pub/layout.:format' do
      format(
        :path => '/webif/pub/manage_layout',
        :format => params[:format],
        :objects => OnBoard::Pub::Layout.read_conf,
        :title  => title
      )
    end

    ['/webif/pub/logo_preview', '/pub/logo'].each do |path|
      get path do
        if logo = OnBoard::Pub::Layout.logo_file
          send_file logo
        else
          not_found
        end
      end
    end

    put '/webif/pub/layout.:format' do
      OnBoard::Pub::Layout.update params
      format(
        :path => '/webif/pub/manage_layout',
        :format => params[:format],
        :objects => OnBoard::Pub::Layout.read_conf,
        :title  => title
      )
    end

  end
end
