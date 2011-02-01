require 'onboard/extensions/erb'
require 'onboard/content-filter/dg/constants'

class OnBoard
  module ContentFilter
    class DG

      def initialize
        reset
      end

      def reset
        @pid = {
          :parent   => nil,
          :children => []
        }
      end

      def running?
        return false if @pid[:parent] == 0
        return @pid[:parent]
      end

      def root
        CONFDIR
      end

      def write_all
        dg = self
        ERB::recurse CONFTEMPLATEDIR, binding, '.erb' do |subpath|
          "#{CONFDIR}/#{subpath}" 
        end
      end

      def get_status
        output = `sudo dansguardian -s`
        status = $!.dup
        if status == 0
          output =~ /(\d+)/ and @pid[:parent] = $1.to_i
          @pid[:children] = 
              `pidof dansguardian`.split.map{|x| x.to_i} - [@pid[:parent]]
        else
          reset
        end
        @dansguardian_s_string = output
      end

    end
  end
end
