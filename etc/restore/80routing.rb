require 'onboard/network/routing'

OnBoard::Network::Routing::Route.restore_static

OnBoard::Network::Routing::Rule.restore(:flush => true)





