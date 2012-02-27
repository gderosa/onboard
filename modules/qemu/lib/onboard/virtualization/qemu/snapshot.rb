require 'fileutils'

class OnBoard
  module Virtualization
    module QEMU
      class Snapshot
      
        def to_json(*a)
          {'i_am' => 'a_stub'}.to_json(*a) 
        end

      end
    end
  end
end

