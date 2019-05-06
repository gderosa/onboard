require 'sinatra/base'

class OnBoard
  class Controller < Sinatra::Base

    # Intended mainly as /api/v1/services/radius/doc
    get '/services/radius/doc.json' do
      redirect 'https://github.com/vemarsas/onboard/blob/radius-api-doc/modules/radius-admin/doc/api/radius-usergroup.md'
    end

  end
end
