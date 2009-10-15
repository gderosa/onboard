$LOAD_PATH.unshift OnBoard::ROOTDIR + '/modules/openvpn/lib'

OnBoard.find_n_load OnBoard::ROOTDIR + '/modules/openvpn/etc/menu'
OnBoard.find_n_load OnBoard::ROOTDIR + '/modules/openvpn/controller'

