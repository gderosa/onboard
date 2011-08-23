require 'onboard/passwd'


class OnBoard
  class Controller

    title = 'Public Interface web layout'

    get '/webif/pub/layout.:format' do 
      format(
        :path => '/webif/pub/manage_layout', 
            # not an erubis layout file, hence the name, to avoid confusion ;-)
        :format => params[:format],
        :objects => nil,
        :title  => title
      )
    end

  end
end
