class OnBoard
  module ContentFilter
    class DG
      ROOTDIR         ||= File.expand_path(
          File.dirname(__FILE__) + '../../../..' )
      CONFDIR         = "#{::OnBoard::CONFDIR}/content-filter/dg"
      TEMPLATEDIR     = "#{ROOTDIR}/templates"
      CONFTEMPLATEDIR = "#{TEMPLATEDIR}/etc/dansguardian"
    end
  end
end
