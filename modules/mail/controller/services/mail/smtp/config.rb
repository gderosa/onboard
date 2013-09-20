require 'sinatra/base'

require 'onboard/service/mail/smtp/config'

class OnBoard
  class Controller < Sinatra::Base

    get '/services/mail/smtp.:format' do
      format(
        :module   => 'mail',
        :path     => '/services/mail/smtp',
        :title    => 'Outgoing Mail Server',
        :format   => params[:format],
        :objects  => Service::Mail::SMTP::Config.get
      )
    end

    put '/services/mail/smtp.:format' do
      smtp      = Service::Mail::SMTP::Config.new params['smtp']
      smtp_orig = Service::Mail::SMTP::Config.get
      if !smtp['password'] or smtp['password'] == ''
        smtp['password'] = smtp_orig['password']
      end
      smtp.save
      same_as_get
    end

  end
end
