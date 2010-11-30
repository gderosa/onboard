class OnBoard
  module Service
    module RADIUS
      DEFAULTS = {
        'dbhost'                => 'localhost',
        'dbname'                => 'radius',
        'dbuser'                => 'radius',
        'dbpass'                => 'radius',

        'accounting'            => {
          'table'                 => 'radacct',
          'columns'               => {
            'Id'                    => 'Radacctid',
            'User-Name'             => 'Username',
            'Famed-IP-Address'      => 'Framedipaddress',
            'NAS-IP-Address'        => 'Nasipaddress',
            'NAS-Port-Type'         => 'Nasporttype',
            'Start Time'            => 'Acctstarttime',
            'Stop Time'             => 'Acctstoptime',
            'Acct-Session-Time'     => 'Acctsessiontime',
            'Acct-Input-Octets'     => 'Acctinputoctets',
            'Acct-Output-Octets'    => 'Acctoutputoctets',
            'Called-Station-Id'     => 'Calledstationid',
            'Calling-Station-Id'    => 'Callingstationid',
            'Acct-Terminate-Cause'  => 'Acctterminatecause',
          }
        }
      }
    end
  end
end
