class OnBoard
  module Service
    module RADIUS
      DEFAULTS = {
        'dbhost'                => 'localhost',
        'dbname'                => 'radius',
        'dbuser'                => 'radius',
        'dbpass'                => 'radius',

        'terms'                 => {
          'table'                 => 'terms',
          'columns'               => {
            'Id'                    => 'id',
            'Name'                  => 'name',
            'Content'               => 'content',
            'Asked'                 => 'asked',
            'Required'              => 'required',
          }
        },

        'terms_accept'          => {
          'table'                 => 'terms_accept',
          'columns'               => {
            'Id'                    => 'id',
            'Personal-Details-Id'   => 'userinfo_id',
            'Terms-Id'              => 'terms_id',
            'Accept'                => 'accept',
          },
        },

        'accounting'            => {
          'table'                 => 'radacct',
          'columns'               => {
            'Id'                    => 'Radacctid',
            'User-Name'             => 'Username',
            'Framed-IP-Address'     => 'Framedipaddress',
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
        },

        'user'                  => {
          'personal'              => {
            'table'                 => 'userinfo',
            'columns'               => {
              'Id'                    => 'id',
              'User-Name'             => 'username',
              'First-Name'            => 'firstname',
              'Last-Name'             => 'lastname',
              'Email'                 => 'email',
              'Work-Phone'            => 'workphone',
              'Home-Phone'            => 'homephone',
              'Mobile-Phone'          => 'mobilephone',
              'Address'               => 'address',
              'City'                  => 'city',
              'State'                 => 'state',
              'Country'               => 'country', # not in DaloRADIUS: use it?
              'Postal-Code'           => 'zip',
              'Notes'                 => 'notes',
              'Creation-Date'         => 'creationdate',
              'Update-Date'           => 'updatedate',

              'Birth-Date'            => 'birthdate',
              'Birth-City'            => 'birthcity',
              'Birth-State'           => 'birthstate',

              'ID-Code'               => 'personalidcode'
            }
          },

          'check'                 => {
            'table'                 => 'radcheck',
            'columns'               => {
              'Id'                    => 'id',

              'User-Name'             => 'username',
                # not really a RADIUS attribute, just for naming consistency...

              'Attribute'             => 'attribute',
              'Operator'              => 'op',
              'Value'                 => 'value'
            }
          },

          'reply'                 => {
            'table'                 => 'radreply',
            'columns'               => {
              'Id'                    => 'id',

              'User-Name'             => 'username',
                # not really a RADIUS attribute, just for naming consistency...

              'Attribute'             => 'attribute',
              'Operator'              => 'op',
              'Value'                 => 'value'
            }
          },
        },

        'group'                 => {

          'check'                 => {
            'table'                 => 'radgroupcheck',
            'columns'               => {
              'Id'                    => 'id',

              'Group-Name'            => 'groupname',
                # not really a RADIUS attribute, just for naming consistency...

              'Attribute'             => 'attribute',
              'Operator'              => 'op',
              'Value'                 => 'value'
            }
          },

          'reply'                 => {
            'table'                 => 'radgroupreply',
            'columns'               => {
              'Id'                    => 'id',

              'Group-Name'            => 'groupname',
                # not really a RADIUS attribute, just for naming consistency...

              'Attribute'             => 'attribute',
              'Operator'              => 'op',
              'Value'                 => 'value'
            }
          },

          'usermap'               => {
            'table'                 => 'radusergroup',
            'columns'               => {
              'User-Name'             => 'username',
              'Group-Name'            => 'groupname',
              'Priority'              => 'priority'
            },
          },
        },

      }
    end
  end
end
