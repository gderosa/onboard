require 'onboard/passwd'


class OnBoard
  class Controller

    title = 'Users and passwords'

    get '/webif/admin/passwd.:format' do 
      format(
        :path => '/webif/admin/passwd',
        :format => params[:format],
        :objects => nil,
        :title  => title
      )
    end

    put '/webif/admin/passwd.:format' do
      msg = OnBoard::Passwd.change_from_HTTP_request(params)
      status msg[:status_http] if msg[:status_http]
      format(
        :path => '/webif/admin/passwd',
        :format => params[:format],
        :objects => nil,
        :msg => msg,
        :title => title
      )
    end
  end
end
