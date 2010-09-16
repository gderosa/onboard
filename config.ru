unless $LOAD_PATH.include? '.' # Ruby 1.9.2
  $LOAD_PATH.unshift '.'
end

require 'onboard'

run OnBoard::Controller

