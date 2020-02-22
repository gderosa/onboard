require 'sinatra/base'

class OnBoard
  class Controller < Sinatra::Base

    # Intended mainly as /api/v1/services/radius -- self-documenting API root
    get '/services/radius.json' do
      paths = {
        'paths' => [
          {
            'description'   => 'RADIUS users',
            'path'          => '/api/v1/services/radius/users',
            'docs'          => 'https://github.com/vemarsas/onboard/blob/margay/modules/radius-admin/doc/api/radius-usergroup.md#part-i-users'
          },
          {
            'description'   => 'RADIUS groups',
            'path'  => '/api/v1/services/radius/groups',
            'docs'  => 'https://github.com/vemarsas/onboard/blob/margay/modules/radius-admin/doc/api/radius-usergroup.md#part-ii-groups'
          }
        ]
      }
      format(:format => 'json', :objects => paths)
    end

    # Intended mainly as /api/v1/services/radius/doc
    get '/services/radius/doc.json' do
      redirect 'https://github.com/vemarsas/onboard/blob/margay/modules/radius-admin/doc/api/radius-usergroup.md'
    end

  end
end
