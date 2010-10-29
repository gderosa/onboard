require 'onboard/extensions/erb'
require 'onboard/content-filter/dg/constants'

class OnBoard
  module ContentFilter
    class DG

      def root
        CONFDIR
      end

      def write_all
        dg = self
        ERB::recurse CONFTEMPLATEDIR, binding, '.erb' do |subpath|
          "#{CONFDIR}/#{subpath}" 
        end
      end

    end
  end
end
