require 'sinatra/base'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/mail/smtp.:format' do
      format(
        :module   => 'mail',
        :path     => '/services/mail/smtp',
        :title    => 'Outgoing Mail Server',
        :format   => params[:format],
        :objects  => {}
      )
    end

  end
end
