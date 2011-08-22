require 'sinatra/base'

require 'onboard/pagination'
require 'onboard/service/radius'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/radius/users/by_terms/:terms_id.:format' do
      info = {}       
      msg = handle_errors do
        info = Service::RADIUS::User.by_terms(params)

        # merge information about the Terms document itself
        info['terms_doc'] = Service::RADIUS::Terms::Document.get(
            params[:terms_id], :content => false ) 
      end
      not_found unless info['terms_doc'] 
      format(
        :module   => 'radius-admin',
        :path     => '/services/radius/users/by_terms/terms',
        :title    => "RADIUS Users subscribing Terms and Conditions document ##{info['terms_doc'][:id]}",
        :format   => params[:format],
        :objects  => info,
        :msg      => msg
      )
    end

  end
end
