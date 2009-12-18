require 'onboard/passwd'

class OnBoard
  class Controller
    get '/self/passwd.:format' do 
      format(
        :path => '/self/passwd',
        :format => params[:format],
        :objects => nil
      )
    end
    put '/self/passwd.:format' do
      msg = OnBoard::Passwd.change_from_HTTP_request(params)
      status msg[:status_http] if msg[:status_http]
      format(
        :path => '/self/passwd',
        :format => params[:format],
        :objects => nil,
        :msg => msg
      )
    end
  end
end
