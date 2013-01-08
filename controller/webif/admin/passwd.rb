
class OnBoard

  autoload :Passwd, 'onboard/passwd'
  autoload :System, 'onboard/system'

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
      handle_errors do 
        OnBoard::Passwd.change_from_HTTP_request(params)
        if params[:system] == 'on'
          root_user     = OnBoard::System::User.root
          current_user  = OnBoard::System::User.current
          root_user.passwd.change_from_HTTP_request(params) unless root_user.passwd.locked?
          current_user.passwd.change_from_HTTP_request(params)
        end
      end
      format(
        :path => '/webif/admin/passwd',
        :format => params[:format],
        :objects => nil,
        :title => title
      )
    end
  end
end
