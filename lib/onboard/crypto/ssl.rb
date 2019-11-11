class OnBoard
  module Crypto
    module SSL
      DATADIR               = OnBoard::CONFDIR + '/crypto/ssl'
      DIR                   = DATADIR
      KEY_SIZES             = [4096, 2048, 1024]

      class << self

        include ERB::Util

        def x509_Name_Hash_to_html_address(h)
          a = []
          a << (html_escape h['O'])                                     if
              h['O']  =~ /\S/
          a << "<span style=\"font-style:italic;\">#{html_escape h['OU']}</span>" if
              h['OU'] =~ /\S/
          s = ''
          s << (html_escape h['L'])                                     if
              h['L']  =~ /\S/
          s << "&nbsp;(#{html_escape h['ST']})"                         if
              h['ST'] =~ /\S/
          a << s                                                        if
              s       =~ /\S/
          a << (html_escape h['C'])                                     if
              h['C'] =~ /\S/
          return a.join(', ')
        end

      end
    end
  end
end

