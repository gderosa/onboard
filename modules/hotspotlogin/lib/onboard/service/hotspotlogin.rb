require 'onboard/system/process'

class OnBoard
  module Service
    class HotSpotLogin

      class MultipleInstances < RuntimeError; end

      def self.getAll
        all = []
        `pidof hotspotlogin.rb`.split.each do |pid|
          all << new(:process => System::Process.new(pid)) 
        end
        raise MultipleInstances, 'More than one hotspotlogin process is running, this situation is unhandled!' if all.length > 1
        return all
      end

      def self.getAll!; @@all = getAll(); end

      def initialize(h)
        @process = h[:process] 
      end

      def data
        @process.data
      end

    end
  end
end

