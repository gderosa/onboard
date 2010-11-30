class OnBoard
  module Service
    module RADIUS
      DEFAULTS = {
        'dbhost' => 'localhost',
        'dbname' => 'radius',
        'dbuser' => 'radius',
        'dbpass' => 'radius',

        'accounting' => {
          'table'     => 'radacct',
          'columns'   => {
            
          }
        }
      }
    end
  end
end
