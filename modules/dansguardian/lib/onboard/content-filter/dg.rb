require 'onboard/content-filter/dg/constants'

class OnBoard
  module ContentFilter
    class DG

      def root
        CONFDIR
      end

      def mkconf
        dg = self
        Dir.glob("#{CONFTEMPLATEDIR}/**/*.erb").each do |file|
          file =~ %r{^#{CONFTEMPLATEDIR}/(.*)$} 
          subpath = $1
          puts $1
        end
      end

    end
  end
end
